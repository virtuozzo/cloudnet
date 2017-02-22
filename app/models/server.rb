# Cloud.net's definition of a server. As opposed to OnApp's definition of a server. It should
# reliably reflect the existence and state of an OnApp Federation server.
class Server < ActiveRecord::Base
  REPORT_FAULTY_VM_EVERY = 7.days

  include PublicActivity::Common
  include Billing::ServerInvoiceable
  include SiftProperties
  include Taggable
  acts_as_paranoid

  # Maximum time for server to be in states such as building, booting, etc
  MAX_TIME_FOR_INTERMEDIATE_STATES = 30.minutes

  # Maximum number of IPs that can be added to a server
  MAX_IPS = 4

  before_save :update_forecasted_revenue
  belongs_to :user
  belongs_to :unscoped_user, -> { unscope(where: :deleted_at) }, foreign_key: :user_id, class_name: "User"
  belongs_to :unscoped_location, -> { unscope(where: :deleted_at) }, foreign_key: :location_id, class_name: "Location"
  belongs_to :template
  belongs_to :location
  has_many :server_events, -> { order transaction_updated: :desc}, dependent: :destroy
  has_many :server_usages, dependent: :destroy
  has_many :server_backups, dependent: :destroy
  has_many :server_hourly_transactions, dependent: :destroy
  has_many :server_ip_addresses, dependent: :destroy
  has_many :unscoped_server_ip_addresses, -> { unscope(where: :deleted_at) }, foreign_key: :server_id, class_name: "ServerIpAddress"
  has_many :server_addons, dependent: :destroy
  has_many :addons, through: :server_addons, dependent: :destroy

  validates :identifier, :hostname, :name, :user, presence: true
  validates :template, :location, presence: true
  validate :template_should_match_location, on: :create
  validates_with HostnameValidator

  enum_field :state, allowed_values: [:pending, :building, :starting_up, :rebooting, :shutting_down, :on, :off ,:blocked, :provisioning], default: :building
  enum_field :payment_type, allowed_values: [:prepaid, :payg], default: :prepaid

  scope :prepaid, -> { where(payment_type: :prepaid) }
  scope :payg, -> { where(payment_type: :payg) }
  scope :created_this_month, -> { where('created_at > ? AND created_at < ?', Time.now.beginning_of_month, Time.now.end_of_month) }
  scope :created_last_month, -> { where('created_at > ? AND created_at < ?', (Time.now - 1.month).beginning_of_month, (Time.now - 1.month).end_of_month) }
  scope :deleted_this_month, -> { where('deleted_at > ? AND deleted_at < ?', Time.now.beginning_of_month, Time.now.end_of_month) }
  scope :deleted_last_month, -> { where('deleted_at > ? AND deleted_at < ?', (Time.now - 1.month).beginning_of_month, (Time.now - 1.month).end_of_month) }
  scope :servers_under_validation, -> { where('validation_reason > 0') }

  TYPE_PREPAID  = 'prepaid'
  TYPE_PAYG     = 'payg'

  NEW_IP_REQUESTED_CACHE = "new_ip_requested_cache"
  BACKUP_CREATED_CACHE = "backup_created_cache"

  def self.provisioner_roles
    return [] unless ENV['DOCKER_PROVISIONER'].present?
    Rails.cache.fetch("provisioner_roles", expires_in: 12.hours) do
      provisioner_roles = DockerProvisionerTasks.new.roles
      JSON.parse(provisioner_roles.body)
    end
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { source: 'Server#provisioner_roles' })
    return []
  end

  def self.purchased_resources
    sums = pluck(:cpus, :memory, :disk_size)
      .inject([0,0,0]) {|sum, o| [sum,o].transpose.map {|x| x.reduce(:+)}}

    {cpu: sums[0], mem: sums[1], disc: sums[2]}
  end

  def self.clear_free_bandwidth(servers)
    servers.each { |s| s.update_attribute(:free_billing_bandwidth, 0)}
  end

  def self.clear_bandwidth_notifications(servers)
    servers.each { |s| s.update(
      exceed_bw_user_notif: 0,
      exceed_bw_value: 0,
      exceed_bw_user_last_sent: nil,
      exceed_bw_admin_notif: 0
      )
    }
  end

  def name_with_ip
    "#{name} (IP: #{primary_ip_address})"
  end

  def to_s
    "#{name}, #{hostname} (Belongs to: #{user})"
  end

  def ip_requested
    ip_requested_cache = Rails.cache.read([Server::NEW_IP_REQUESTED_CACHE, id])
    ip_requested_cache.nil? ? 0 : ip_requested_cache
  end

  def ip_requested=(count)
    if count > 0
      Rails.cache.write([Server::NEW_IP_REQUESTED_CACHE, id], count)
    else
      Rails.cache.delete([Server::NEW_IP_REQUESTED_CACHE, id])
    end
  end

  def ip_addresses
    server_ip_addresses.count + ip_requested
  end

  def primary_ip_address
    @primary_ip_address ||= begin
      server_ip_addresses.with_deleted.present? ? ((server_ip_addresses.with_deleted.find(&:primary?) || server_ip_addresses.with_deleted.first).address) : nil
    end
  end

  # Returns the primary network interface of server from Onapp, useful when assigning new IP
  def primary_network_interface
    server_task = ServerTasks.new
    interfaces = server_task.perform(:get_network_interfaces, user.id, id)
    primary = interfaces.find { |interface| interface['network_interface']['primary'] == true }
    primary['network_interface']
  rescue
    nil
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
      unless stuck
        AdminMailer.notify_stuck_server_state(self).deliver_now
        NotifyUsersMailer.notify_stuck_state(user, self).deliver_now
      end
    end
    update_attribute :stuck, detected_stuck if detected_stuck != stuck
  end

  # Notify admin if server has no storage attached or no IPs
  def notify_fault(no_disk, no_ip)
    add_remove_tags_by_hash(no_disk: no_disk, no_ip: no_ip)
    return unless no_disk || no_ip
    days_since_creation = ((Time.now - created_at) / 1.day).floor
    last_warning_threshold = case fault_reported_at
      when nil then 1
      else ((Time.now - fault_reported_at) / REPORT_FAULTY_VM_EVERY).floor
    end
    if days_since_creation >= 1 && last_warning_threshold >= 1
      AdminMailer.notify_faulty_server(self, no_disk, no_ip).deliver_now
      update_attribute :fault_reported_at, Time.now
      create_activity :faulty_server_report, owner: user, params: { no_disk: no_disk, no_ip: no_ip}
    end
  end

  # Change the resources for a server in our DB. Does not sync these changes to the server on the
  # Federation. It is true that, should the server be updated through the Federation API, then our
  # worker processes will eventually update the server anyway. But updating the server before the
  # Federation does, gives instant feedback to the user that their server has been updated.
  #
  # `resources` hash, new resources for server
  def edit(resources, store = true)
    resources.stringify_keys!
    editable_properties = %w(name cpus memory disk_size template_id addon_ids)
    updates = {}
    editable_properties.each do |field|
      updates[field] = resources[field] if resources.key? field
    end
    if store
      update_attributes!(updates)
    else
      assign_attributes(updates)
    end
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

  # Check temp cache of IP count is within permissible limit of IPs that can be added to a server, also check if location supports multiple IPs
  def can_add_ips?
    return false if state != :on && state != :off
    supports_multiple_ips? && (ips_chargeable? || ip_addresses < MAX_IPS)
  end

  def ips_chargeable?
    location.price_ip_address.to_f > 0
  end

  # Check if version of Onapp supports multiple IPs - should be 4.1.0+
  def supports_multiple_ips?
    Gem::Version.new(location.hv_group_version) >= Gem::Version.new('4.1.0')
  end

  # Check if version of Onapp supports manual backups - should be 4.0.0+
  def supports_manual_backups?
    Gem::Version.new(location.hv_group_version) >= Gem::Version.new('4.0.0')
  end

  def supports_root_password_reset?
    Gem::Version.new(location.hv_group_version) >= Gem::Version.new('4.2.0')
  end

  def no_auto_refresh!
    update_attribute(:no_refresh, true)
  end

  def auto_refresh_on!
    update_attribute(:no_refresh, false)
  end

  def update_forecasted_revenue
    self.forecasted_rev = forecasted_revenue
  end

  def forecasted_revenue
    return 0.0 if user.suspended?
    discount = (1 - coupon_percentage).round(3)
    (monthly_price * discount).round
  end

  def monthly_price
    (location.hourly_price(memory, cpus, disk_size) * Account::HOURS_MAX).round
  end

  def coupon_percentage
    coupon = user.account.coupon
    if coupon.present? then coupon.percentage_decimal else 0 end
  end

  def refresh_usage
    RefreshServerUsages.new.refresh_server_usages(self)
  rescue => e
    ErrorLogging.new.track_exception(e, extra: { source: 'Server#refresh_usage', server_id: id })
    # raise error - for not invoicing when user suspended at onapp or server does not exist
    raise e if e.is_a?(Faraday::ClientError) && e.to_s =~ /[401,404]/
  end

  def inform_if_bandwidth_exceeded
    BandwidthChecker.new(self).check_bandwidth
  end

  def provisioned?
    !provisioned_at.nil?
  end

  def can_provision?
    !provisioner_role.nil? && validation_reason == 0 && !provisioned?
  end

  def monitor_and_provision
    docker_provision = can_provision?
    no_auto_refresh! if docker_provision
    MonitorServer.perform_in(MonitorServer::POLL_INTERVAL.seconds, id, user_id, docker_provision)
    DockerCreation.perform_in(MonitorServer::POLL_INTERVAL.seconds, id, provisioner_role) if docker_provision
  end
  
  def install_ssh_keys(keys)
    InstallKeys.perform_in(MonitorServer::POLL_INTERVAL.seconds, id, keys)
  end
  
  def process_addons
    ProcessAddons.new(self).process
  end

  def supports_rebuild?
    !(try(:os) == "windows" || try(:provisioner_role))
  end

  private

  def template_should_match_location
    unless location && template && location.templates.where(hidden: false).exists?(template.id)
      errors.add(:server, 'Template does not match location')
      return false
    end
  end
end
