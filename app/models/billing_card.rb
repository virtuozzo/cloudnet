class BillingCard < ActiveRecord::Base
  include SiftProperties
  
  belongs_to :account
  acts_as_paranoid

  validates :bin, :ip_address, :user_agent, :city, :country,
            :region, :postal, :expiry_month, :expiry_year,
            :cardholder, :last4, :account, :address1, presence: true

  validate :verify_valid_country_code
  validate :phone_verification, on: :create
  
  before_destroy :verify_card_deletable

  validates_format_of :expiry_month, with: /\A(0[1-9]|1[0-2])\z/
  validates_format_of :expiry_year, with: /\A(1[4-9]|2[0-9])\z/
  validates_format_of :bin, with: /\A([0-9]{6})\z/
  validates_format_of :last4, with: /\A([0-9]{4})\z/

  scope :processable, -> { select(&:processable?) }

  def processable?
    processor_token.present? && fraud_verified
  end

  def fraud_assessment
    if account.maxmind_exempt?
      return { assessment: :safe }
    end

    unless fraud_verified
      return { assessment: :unassessed }
    end

    case fraud_score
    when 0..15
      { assessment: :safe }
    when 15..40
      { assessment: :validate }
    when 40..100
      { assessment: :rejected }
    else
      { assessment: :validate }
    end
  end

  def primary=(primary)
    if primary == true
      cards = BillingCard.where(account: account, primary: true)
      cards.each { |c| c.update(primary: false) }
    end

    write_attribute(:primary, primary)
  end
  
  def set_new_primary
    card = BillingCard.where(account: account, primary: false).order(created_at: :desc).first
    card.update(primary: true) unless card.blank?
  end

  private

  def verify_valid_country_code
    errors.add(:country, 'Invalid Country Selected') unless country && IsoCountryCodes.all.detect { |c| c.alpha2.downcase == country.downcase }
  end
  
  def phone_verification
    return true unless KEYS[:nexmo][:api_key].present?
    errors.add(:base, 'Phone number is not verified. A verified phone number is required to add a credit card.') unless account.user.phone_verified?
  end
  
  def verify_card_deletable
    account.billing_cards.count > 1
  end
end
