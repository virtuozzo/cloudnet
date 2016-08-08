class PaymentReceipt < ActiveRecord::Base
  include CreditPaymentsShared
  include Metadata
  include SiftProperties

  acts_as_paranoid
  acts_as_sequenced start_at: 1

  belongs_to :account
  validates :account, presence: true

  validate :remaining_cost_can_not_be_negative
  enum_field :state, allowed_values: [:uncredited, :credited], default: :credited
  enum_field :pay_source, allowed_values: [:paypal, :billing_card]

  def self.create_receipt(account, amount, source)
    receipt = PaymentReceipt.new(pay_source: source, net_cost: amount, account: account)
  end

  def account=(account)
    super(account)
    self.billing_address = account.billing_address if account.billing_address
  end

  def receipt_number
    "PR#{sequential_id.to_s.rjust(7, '0')}"
  end
  
  alias_method :number, :receipt_number

  def remaining_cost
    read_attribute(:remaining_cost) || net_cost
  end

  def billing_address=(address)
    write_attribute(:billing_address, address.to_json)
  end

  def billing_address
    address = read_attribute(:billing_address)

    if address.present?
      JSON.parse(address).deep_symbolize_keys
    else
      nil
    end
  end
  
  def billing_card
    account.billing_cards.find_by_processor_token metadata[:card][:id] rescue nil
  end

  def pretty_pay_source
    pay_source.to_s.split('_').map(&:capitalize).join(' ')
  end
  
  def create_sift_event
    CreateSiftEvent.perform_async("$transaction", sift_payment_receipt_properties)
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: account.user.id, source: 'PaymentReceipt#create_sift_event' })
  end

  private

  def remaining_cost_can_not_be_negative
    errors.add(:remaining_cost, 'Can not be negative') if remaining_cost < 0
  end
end
