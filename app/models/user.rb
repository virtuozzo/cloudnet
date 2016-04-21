class User < ActiveRecord::Base
  include PublicActivity::Common
  include User::Limitable
  include NegativeBalanceProtection
  include NegativeBalanceProtection::ActionStrategies
  include NegativeBalanceProtection::Actions
  
  acts_as_paranoid

  devise :otp_authenticatable, :database_authenticatable, :registerable, :confirmable, :lockable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :servers, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :dns_zones, dependent: :destroy
  has_one :account, dependent: :destroy
  has_many :keys, dependent: :destroy
  has_many :server_count_history, class: UserServerCount, dependent: :destroy

  enum_field :status, allowed_values: [:active, :pending, :suspended], default: :pending

  validates :full_name, presence: true
  # validate :whitelisted_email, on: :create

  # We want the password field to be symmetrically encrypted so we can grab
  # the contents later on if need be. This stores a value in encrypted_onapp_password
  attr_encrypted :onapp_password

  # We want to create an account for the user in question for billing purposes
  after_create :create_account

  # TODO: Make sure our worker is triggered. This should probably be in the controller
  # since it's triggering a worker we can only guarantee it in the model for each user
  after_create :create_onapp_user
  
  # Create contact at AgileCRM
  after_create :update_agilecrm_contact

  # Analytics tracking
  after_create :track_analytics

  scope :created_this_month, -> { where('created_at > ? AND created_at < ?', Time.now.beginning_of_month, Time.now.end_of_month) }
  scope :created_last_month, -> { where('created_at > ? AND created_at < ?', (Time.now - 1.month).beginning_of_month, (Time.now - 1.month).end_of_month) }
  scope :servers_to_be_destroyed, -> { where("notif_delivered - notif_before_destroy >= 0")}
  
  def to_s
    "#{full_name}"
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
    account.billing_cards.with_deleted.count == 0
  end
  
  def after_database_authentication
    update_agilecrm_contact
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
  
  def update_agilecrm_contact
    UpdateAgilecrmContact.perform_async(id)
  end

  def track_analytics
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
  
  # def whitelisted_email
  #   if Rails.env.production? && EmailWhitelist.find_by_email(self.email).nil?
  #     errors.add(:email, "currently hasn't received an invite. Please use the exact email you used to signup to the Cloud.net Beta")
  #     false
  #   end
  # end
end
