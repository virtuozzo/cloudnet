# Cloud.net's definition of a server. As opposed to OnApp's definition of a server. It should 
# reliably reflect the existience and state of an OnApp Federation server.
class Server < ActiveRecord::Base
  include PublicActivity::Common
  include Billing::ServerInvoiceable
  acts_as_paranoid
  
  # Maximum time for server to be in states such as building, booting, etc
  MAX_TIME_FOR_INTERMEDIATE_STATES = 30.minutes

  belongs_to :user
  belongs_to :template
  belongs_to :location
  has_many :server_events, dependent: :destroy
  has_many :server_usages, dependent: :destroy
  has_many :server_backups, dependent: :destroy
  has_many :server_hourly_transactions, dependent: :destroy

  validates :identifier, :hostname, :name, :user, presence: true
  validates :template, :location, presence: true
  validate :template_should_match_location, on: :create
  validates_with HostnameValidator

  enum_field :state, allowed_values: [:pending, :building, :starting_up, :rebooting, :shutting_down, :on, :off], default: :building
  enum_field :payment_type, allowed_values: [:prepaid, :payg], default: :prepaid

  scope :prepaid, -> { where(payment_type: :prepaid) }
  scope :payg, -> { where(payment_type: :payg) }
  scope :created_this_month, -> { where('created_at > ? AND created_at < ?', Time.now.beginning_of_month, Time.now.end_of_month) }
  scope :created_last_month, -> { where('created_at > ? AND created_at < ?', (Time.now - 1.month).beginning_of_month, (Time.now - 1.month).end_of_month) }
  scope :deleted_this_month, -> { where('deleted_at > ? AND deleted_at < ?', Time.now.beginning_of_month, Time.now.end_of_month) }
  scope :deleted_last_month, -> { where('deleted_at > ? AND deleted_at < ?', (Time.now - 1.month).beginning_of_month, (Time.now - 1.month).end_of_month) }

  TYPE_PREPAID  = 'prepaid'
  TYPE_PAYG     = 'payg'

  def name_with_ip
    "#{name} (IP: #{primary_ip_address})"
  end

  def to_s
    "#{name}, #{hostname} (Belongs to: #{user})"
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

  def notify_if_stuck_state
    return if state.in? [:off, :on] # These are known stable states
    return unless Time.zone.now - last_state_change > MAX_TIME_FOR_INTERMEDIATE_STATES
    AdminMailer.notify_stuck_server_state(self).deliver_now
  end

  # Change the resources for a server in our DB. Does not sync these changes to the server on the
  # Federation. It is true that, should the server be updated through the Federation API, then our
  # worker processes will eventually update the server anyway. But updating the server before the
  # Federation does, gives instant feedback to the user that their server has been updated.
  #
  # `resources` hash, new resources for server
  def edit(resources)
    resources.stringify_keys!
    editable_properties = %w(name cpus memory)
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

  private

  def template_should_match_location
    unless location && template && location.templates.where(hidden: false).exists?(template.id)
      errors.add(:server, 'Template does not match location')
      return false
    end
  end
end
