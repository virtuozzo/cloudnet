class User < ActiveRecord::Base
  include PublicActivity::Common
  include User::Limitable
  include NegativeBalanceProtection
  include NegativeBalanceProtection::ActionStrategies
  include NegativeBalanceProtection::Actions
  include SiftProperties
  include User::SiftUser
  include Taggable
  include User::PhoneNumber

  class Unauthorized < StandardError; end

  acts_as_paranoid

  devise :otp_authenticatable, :database_authenticatable, :registerable, :confirmable, :lockable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :servers, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :dns_zones, dependent: :destroy
  has_one :account, dependent: :destroy
  has_many :keys, dependent: :destroy
  has_many :server_count_history, class_name: UserServerCount, dependent: :destroy
  has_many :api_keys, dependent: :destroy

  enum_field :status, allowed_values: [:active, :pending, :suspended], default: :pending

  validates :full_name, presence: true
  validate :disposable_emails
  # validate :whitelisted_email, on: :create
  validates :phone_number, :unverified_phone_number, presence: true, allow_nil: true
  validates_uniqueness_of :phone_number, allow_nil: true
  validates :phone_number, :unverified_phone_number, phone: { possible: false, allow_blank: true, types: [:mobile] }

  # We want the password field to be symmetrically encrypted so we can grab
  # the contents later on if need be. This stores a value in encrypted_onapp_password
  attr_encrypted :onapp_password

  # We want to create an account for the user in question for billing purposes
  after_create :create_account

  # TODO: Make sure our worker is triggered. This should probably be in the controller
  # since it's triggering a worker we can only guarantee it in the model for each user
  after_create :create_onapp_user

  # Analytics tracking
  after_create :track_analytics

  scope :created_this_month, -> { where('created_at > ? AND created_at < ?', Time.now.beginning_of_month, Time.now.end_of_month) }
  scope :created_last_month, -> { where('created_at > ? AND created_at < ?', (Time.now - 1.month).beginning_of_month, (Time.now - 1.month).end_of_month) }
  scope :servers_to_be_destroyed, -> { where("notif_delivered - notif_before_destroy >= 0")}

  def to_s
    "#{full_name}"
  end

  def self.api_authenticate(auth_header)
    split_header = auth_header.delete("\n").split
    type = split_header[0].strip
    credential = split_header[1].try(:strip)

    if type == 'Basic'
      email, api_key = *Base64.decode64(credential).split(':')
      user = find_by! email: email.encode("UTF-8")
      if user.valid_api_key?(api_key)
        user
      else
        raise(Unauthorized, 'Unauthorized')
      end
    else
      raise(Unauthorized, "Invalid Authorization header. Use: 'Authorization: Basic encoded64(yourEmail:yourAPIKey)'")
    end
  rescue Encoding::UndefinedConversionError
    raise(Unauthorized, 'Make sure you encoded64 yourEmail:APIkey sequence')
  end

  def valid_api_key?(api_key)
    encrypted = SymmetricEncryption.encrypt api_key
    api_keys.where(active: true).pluck(:encrypted_key).include?(encrypted)
  end

  def active_for_authentication?
    super && !suspended?
  end

  def inactive_message
    !suspended? ? super : :user_suspended
  end

  def act_for_negative_balance
    strategy = UserConstraintsAdminConfirm
    Protector.fire_counter_actions(self, strategy)
  end

  def clear_unpaid_notifications(reason = nil)
    return if notif_delivered == 0
    clear_notifications_activity(reason) if reason
    update(
      notif_delivered: 0,
      last_notif_email_sent: nil,
      admin_destroy_request: RequestForServerDestroyEmailToAdmin::REQUEST_NOT_SENT
      )
  end

  def clear_notifications_activity(reason)
    create_activity(
      :clear_notifications,
      owner: self,
      params: { reason: reason,
                balance: Invoice.pretty_total(account.remaining_balance * -1),
                from: notif_delivered
              }
    )
  end

  def refresh_my_servers
    servers.each do |server|
      ServerTasks.new.perform(:refresh_server, id, server.id) rescue nil
    end
  end

  def server_destroy_scheduled?
    admin_destroy_request == RequestForServerDestroyEmailToAdmin::REQUEST_SENT_CONFIRMED
  end

  def confirm_automatic_destroy
    update_attribute(:admin_destroy_request,
                    RequestForServerDestroyEmailToAdmin::REQUEST_SENT_CONFIRMED)
  end

  def unconfirm_automatic_destroy
    update_attribute(:admin_destroy_request,
                    RequestForServerDestroyEmailToAdmin::REQUEST_SENT_NOT_CONFIRMED)
  end

  def servers_blocked?
    notif_delivered > notif_before_shutdown
  end

  def trial_credit_eligible?
    account.billing_cards.with_deleted.processable.count == 0
  end

  def after_database_authentication
    update_sift_account
    create_sift_login_event
  end

  def update_sift_account
    CreateSiftEvent.perform_async("$update_account", sift_user_properties)
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: self.id, source: 'User#update_sift_account' })
  end

  def update_forecasted_revenue
    servers.each {|server| server.update_attribute(:forecasted_rev, server.forecasted_revenue)}
  end

  def forecasted_revenue
    servers.reduce(0) {|result, server| result + server.forecasted_rev}
  end

  def create_sift_account(include_time_ip = false)
    properties = sift_user_properties(include_time_ip)
    CreateSiftEvent.perform_async("$create_account", properties)
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: self.id, source: 'User#create_sift_account' })
  end

  def create_sift_login_event
    properties = {
      "$user_id"      => id,
      "$session_id"   => anonymous_id,
      "$login_status" => "$success"
    }
    CreateSiftEvent.perform_async("$login", properties)
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: self.id, source: 'User#create_sift_login_event' })
  end

  def self.disposable_email_domains
    Rails.cache.fetch("disposable_email_domains") do
      CSV.read("#{Rails.root}/db/disposable_email_domains.csv").flatten
    end
  end
  
  def cache_key_for_servers
    server_count = servers.size
    server_max_updated_at = servers.maximum(:updated_at).try(:utc).try(:to_s, :number)
    "#{id}/servers/all-#{server_count}-#{server_max_updated_at}"
  end
  
  def intercom_user_hash
    OpenSSL::HMAC.hexdigest('sha256', KEYS[:intercom][:secret_key], id.to_s)
  end
  
  def intercom_location_hash
    Rails.cache.fetch(["location_hash", cache_key_for_servers]) do
      servers.with_deleted.map(&:location).uniq.map(&:short_label).join(', ')
    end
  end
  
  def whitelisted?
    !account.nil? && account.whitelisted?
  end

  protected

  def send_on_create_confirmation_instructions
    unless @raw_confirmation_token
      generate_confirmation_token!
    end

    WelcomeMailer.welcome_email(self, @raw_confirmation_token).deliver_now
  end

  private

  def create_account
    self.account ||= Account.create!(user: self)
  end

  def create_onapp_user
    CreateOnappUser.perform_async(id)
  end

  def track_analytics
    return true if KEYS[:analytics][:token].nil?
    Analytics.service.alias(previous_id: anonymous_id, user_id: id) unless anonymous_id.nil?
    Analytics.service.flush

    Analytics.service.identify(
      user_id: id,
      traits: {
        name: full_name,
        email: email,
        created_at: created_at
      }
    )
    Analytics.track(self, event: "New User Created")
  end

  def anonymous_id
    Thread.current[:session_id]
  end

  def disposable_emails
    email_domain = Mail::Address.new(email).domain
    if User.disposable_email_domains.include? email_domain
      errors.add(:email, "is a disposable email address. Please use a genuine email address.")
      false
    end
  end

  # def whitelisted_email
  #   if Rails.env.production? && EmailWhitelist.find_by_email(self.email).nil?
  #     errors.add(:email, "currently hasn't received an invite. Please use the exact email you used to signup to the Cloud.net Beta")
  #     false
  #   end
  # end
end
