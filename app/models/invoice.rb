class Invoice < ActiveRecord::Base
  include InvoiceCreditShared
  include SiftProperties

  acts_as_paranoid
  acts_as_sequenced start_at: 1

  belongs_to :account
  has_many :invoice_items, dependent: :destroy
  has_many :charges, dependent: :destroy
  belongs_to :coupon

  validates :account, presence: true
  enum_field :state, allowed_values: [:unpaid, :partially_paid, :paid], default: :unpaid
  enum_field :invoice_type, allowed_values: [:prepaid, :payg], default: :prepaid

  scope :prepaid, -> { where(invoice_type: :prepaid) }
  scope :payg, -> { where(invoice_type: :payg) }
  scope :not_paid, -> { where.not(state: :paid) }

  after_create :create_sift_event
  before_create :coupon_should_not_present_if_payg

  TAX_RATE             = 0.2  # Define as a decimal always!
  CENTS_IN_DOLLAR      = 1000.0
  MILLICENTS_IN_DOLLAR = CENTS_IN_DOLLAR * 100.0
  MICROS_IN_DOLLAR     = MILLICENTS_IN_DOLLAR * 10.0
  MICROS_IN_MILLICENT  = 10.0
  USD_GBP_RATE         = 0.8
  MIN_CHARGE_AMOUNT    = 100

  def self.generate_prepaid_invoice(invoiceables, account, hours = nil, reason = false)
    invoice = Invoice.new(account: account)
    hours ||= invoice.hours_till_next_invoice
    items = invoiceables.map { |i| InvoiceItem.new i.generate_invoice_item(hours, reason).merge(invoice: invoice) }
    invoice.invoice_items = items
    invoice
  end

  def self.generate_payg_invoice(invoiceables, account)
    invoice = Invoice.new(account: account, invoice_type: :payg)

    date_range = account.past_invoice_date_past_months(1.month)..account.past_invoice_date
    items = invoiceables.map do |i|
      transactions = i.transactions(date_range)
      InvoiceItem.new i.generate_payg_invoice_item(transactions).merge(invoice: invoice)
    end

    invoice.invoice_items = items
    invoice
  end

  # Generate PAYG invoice from last invoiced date until today, to the hour
  def self.generate_final_payg_invoice(invoiceables, account)
    invoice = Invoice.new(account: account, invoice_type: :payg)

    date_range = account.past_invoice_due..Time.zone.now
    items = invoiceables.map do |i|
      transactions = i.transactions(date_range)
      InvoiceItem.new i.generate_payg_invoice_item(transactions).merge(invoice: invoice)
    end

    invoice.invoice_items = items
    invoice
  end

  def increase_free_billing_bandwidth(old_bw)
    return unless old_bw
    invoice_items.each { |i| i.increase_free_billing_bandwidth(old_bw) }
  end

  def items?
    invoice_items.length > 0
  end

  def invoice_number
    "IN#{sequential_id.to_s.rjust(7, '0')}"
  end

  def number
    invoice_number
  end

  def remaining_cost
    total_cost - charges.inject(0) { |sum, charge| sum + charge.amount }
  end

  def prepaid?
    invoice_type == Server::TYPE_PREPAID.to_sym
  end

  def payg?
    invoice_type == Server::TYPE_PAYG.to_sym
  end

  def create_sift_event
    CreateSiftEvent.perform_async("$create_order", sift_invoice_properties)
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: account.user.id, source: 'Invoice#create_sift_event' })
  end

  private

  def coupon_should_not_present_if_payg
    self.coupon_id = nil if payg?
  end

  def cost_from_items(type)
    if items?
      invoice_items.inject(0) { |total, item| total + item.send(type) }
    else
      0
    end
  end
end
