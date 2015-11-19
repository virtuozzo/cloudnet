# Cloud.net's definition of a server. As opposed to OnApp's definition of a server. It should
# reliably reflect the existence and state of an OnApp Federation server.
class Server < ActiveRecord::Base
  include PublicActivity::Common
  include Billing::ServerInvoiceable
  acts_as_paranoid

  # Maximum time for server to be in states such as building, booting, etc
  MAX_TIME_FOR_INTERMEDIATE_STATES = 30.minutes
  
  # Maximum number of IPs that can be added to a server
  MAX_IPS = 2

  belongs_to :user
  belongs_to :template
  belongs_to :location
  has_many :server_events, dependent: :destroy
  has_many :server_usages, dependent: :destroy
  has_many :server_backups, dependent: :destroy
  has_many :server_hourly_transactions, dependent: :destroy
  has_many :server_ip_addresses, dependent: :destroy

  validates :identifier, :hostname, :name, :user, presence: true
  validates :template, :location, presence: true
  validate :template_should_match_location, on: :create
  validates_with HostnameValidator

  enum_field :state, allowed_values: [:pending, :building, :starting_up, :rebooting, :shutting_down, :on, :off ,:blocked], default: :building
  enum_field :payment_type, allowed_values: [:prepaid, :payg], default: :prepaid

  scope :prepaid, -> { where(payment_type: :prepaid) }
  scope :payg, -> { where(payment_type: :payg) }
  scope :created_this_month, -> { where('created_at > ? AND created_at < ?', Time.now.beginning_of_month, Time.now.end_of_month) }
  scope :created_last_month, -> { where('created_at > ? AND created_at < ?', (Time.now - 1.month).beginning_of_month, (Time.now - 1.month).end_of_month) }
  scope :deleted_this_month, -> { where('deleted_at > ? AND deleted_at < ?', Time.now.beginning_of_month, Time.now.end_of_month) }
  scope :deleted_last_month, -> { where('deleted_at > ? AND deleted_at < ?', (Time.now - 1.month).beginning_of_month, (Time.now - 1.month).end_of_month) }

  TYPE_PREPAID  = 'prepaid'
  TYPE_PAYG     = 'payg'
  
  IP_ADDRESSES_COUNT_CACHE = "ip_addresses_count_cache"
  IP_ADDRESS_ADDED_CACHE = "ip_address_added_cache"
  BACKUP_CREATED_CACHE = "backup_created_cache"

  def self.purchased_resources
    sums = pluck(:cpus, :memory, :disk_size)
      .inject([0,0,0]) {|sum, o| [sum,o].transpose.map {|x| x.reduce(:+)}}

    {cpu: sums[0], mem: sums[1], disc: sums[2]}
  end

  def name_with_ip
    "#{name} (IP: #{primary_ip_address})"
  end

  def to_s
    "#{name}, #{hostname} (Belongs to: #{user})"
  end
  
  def primary_ip_address
    return (server_ip_addresses.with_deleted.find(&:primary?) || server_ip_addresses.with_deleted.first).address if server_ip_addresses.with_deleted.present?
    nil
  end
  
  # Returns the primary network interface of server from Onapp, useful when assigning new IP
  def primary_network_interface
    server_task = ServerTasks.new
    interfaces = server_task.perform(:get_network_interfaces, user.id, id)
    primary = interfaces.find { |interface| interface['network_interface']['primary'] == true }
    primary['network_interface']
  end

  def destroy_with_ip(ip)
    update!(delete_ip_address: ip)
    destroy
  end

  def prepaid?
    payment_type == Server::TYPE_PREPAID.to_sym
  end

  def payg?
    payment_type == Server::TYPE_PAYG.to_sym
  end

  def note_time_of_state_change
    update_attributes!(state_changed_at: Time.zone.now)
  end

  def last_state_change
    state_changed_at || created_at
  end

  def detect_stuck_state
    detected_stuck = false
    has_intermediate_state = !state.in?([:off, :on, :blocked])
    time_in_state = Time.zone.now - last_state_change
    if has_intermediate_state && time_in_state > MAX_TIME_FOR_INTERMEDIATE_STATES
      detected_stuck = true
      # Only respond to a stuck state the first time it is detected
      AdminMailer.notify_stuck_server_state(self).deliver_now unless stuck
    end
    update_attributes(stuck: detected_stuck) if detected_stuck != stuck
  end

  # Change the resources for a server in our DB. Does not sync these changes to the server on the
  # Federation. It is true that, should the server be updated through the Federation API, then our
  # worker processes will eventually update the server anyway. But updating the server before the
  # Federation does, gives instant feedback to the user that their server has been updated.
  #
  # `resources` hash, new resources for server
  def edit(resources)
    resources.stringify_keys!
    editable_properties = %w(name cpus memory disk_size template_id)
    updates = {}
    editable_properties.each do |field|
      updates[field] = resources[field] if resources.key? field
    end
    update_attributes! updates
  end

  # Check whether the current resources attributed to the server match a given package.
  # Used when editing a server, it's useful to highlight a package option if it matches the current
  # resources.
  # TODO; there is a duplicate function in ServerWizard, choose one or the other.
  #
  # `package` instance of Package model
  def matches_package?(package)
    %w(memory cpus disk_size).each do |resource|
      return false if send(resource) != package.send(resource)
    end
    true
  end

  # Blocks until server has the :on state. Used mainly during testing
  def wait_until_ready
    reload
    server_task = ServerTasks.new
    start = Time.now
    until locked == false
      sleep 60 # Too many request can fill up VCR cassettes
      server_task.perform(:refresh_server, user.id, id)
      reload
      break if Time.now - start > 10.minutes
    end
  end
  
  # Check temp cache of IP count is withing permissible limit of IPs that can be added to a server, also check if location supports multiple IPs
  def can_add_ips?
    return false if state != :on && state != :off
    ips_count = Rails.cache.read([Server::IP_ADDRESSES_COUNT_CACHE, id]) || server_ip_addresses.count
    supports_multiple_ips? && (ips_count < MAX_IPS)
  end
  
  # Check if version of Onapp supports multiple IPs - should be 4.1.0+
  def supports_multiple_ips?
    Gem::Version.new(location.hv_group_version) >= Gem::Version.new('4.1.0')
  end
  
  # Check if version of Onapp supports manual backups - should be 4.0.0+
  def supports_manual_backups?
    Gem::Version.new(location.hv_group_version) >= Gem::Version.new('4.0.0')
  end

  private

  def template_should_match_location
    unless location && template && location.templates.where(hidden: false).exists?(template.id)
      errors.add(:server, 'Template does not match location')
      return false
    end
  end
end
