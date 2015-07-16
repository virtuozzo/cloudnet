class User < ActiveRecord::Base
  include PublicActivity::Common
  include User::Limitable

  acts_as_paranoid

  devise :otp_authenticatable, :database_authenticatable, :registerable, :confirmable, :lockable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :servers, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :dns_zones, dependent: :destroy
  has_one :account, dependent: :destroy

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

  # Analytics tracking
  after_create :track_analytics

  scope :created_this_month, -> { where('created_at > ? AND created_at < ?', Time.now.beginning_of_month, Time.now.end_of_month) }
  scope :created_last_month, -> { where('created_at > ? AND created_at < ?', (Time.now - 1.month).beginning_of_month, (Time.now - 1.month).end_of_month) }

  def to_s
    "#{full_name}"
  end

  def active_for_authentication?
    super && !suspended?
  end

  def inactive_message
    !suspended? ? super : :user_suspended
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
    Analytics.service.alias(previous_id: anonymous_id, user_id: id)
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
