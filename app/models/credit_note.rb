# A credit note is issued by cloud.net to a client. Most often one will be created when a server
# that's being paid for from a prepaid account is destroyed. Typically a client will have paid, say
# $5 dollars for a month's usage, but then the server is destroyed before then month's end. They
# aren't refunded directly into their bank, but their cloud.net balance is credited to reflect the
# unused server usage.
class CreditNote < ActiveRecord::Base
  include InvoiceCreditShared
  include CreditPaymentsShared
  include SiftProperties

  acts_as_paranoid
  acts_as_sequenced start_at: 1

  belongs_to :account
  has_many :credit_note_items, dependent: :destroy
  belongs_to :coupon
  
  validates :account, presence: true

  enum_field :state, allowed_values: [:uncredited, :credited], default: :credited

  validate :remaining_cost_can_not_be_negative
  
  after_create :create_sift_event
  
  TRIAL_CREDIT = 10

  # `invoiceables` are generally servers
  def self.generate_credit_note(invoiceables, account, last_invoice = nil)
    credit = CreditNote.new(account: account)
    hours  = credit.generate_credit_hours(last_invoice)
    items  = invoiceables.map { |c| CreditNoteItem.new c.generate_credit_item(hours).merge(credit_note: credit) }
    credit.credit_note_items = items
    credit
  end

  def generate_credit_hours(last_invoice, today=Time.now)
    if last_invoice.present?
      last_invoice_date = last_invoice.created_at
      hours_paid = [account.hours_till_next_invoice(last_invoice_date, today), Account::HOURS_MAX].min
      hours_used = ([(today - last_invoice_date) / 1.hour, Account::HOURS_MAX].min)
      (hours_paid - hours_used).floor.abs
    else
      hours_till_next_invoice
    end
  end

  def hours_till_next_invoice
    CreditNote.hours_till_next_invoice(account)
  end

  def self.hours_till_next_invoice(account)
    [account.hours_till_next_invoice, Account::HOURS_MAX].min - 1
  end

  def items?
    credit_note_items.length > 0
  end

  def credit_number
    "CR#{sequential_id.to_s.rjust(7, '0')}"
  end

  def number
    credit_number
  end
  
  def create_sift_event
    CreateSiftEvent.perform_async("$transaction", sift_credit_note_properties)
  rescue StandardError => e
    ErrorLogging.new.track_exception(e, extra: { user: account.user.id, source: 'CreditNote#create_sift_event' })
  end

  private

  def remaining_cost_can_not_be_negative
    errors.add(:remaining_cost, 'Can not be negative') if remaining_cost < 0
  end

  def cost_from_items(type, scopes = nil)
    if items?
      if scopes
        credit_note_items.send(scopes).inject(0) { |total, item| total + item.send(type) }
      else
        credit_note_items.inject(0) { |total, item| total + item.send(type) }
      end
    else
      0
    end
  end

  # Was this credit note manually issued throught the admin interface?
  def manually_added?
    if credit_note_items.size == 1
      return true if credit_note_items.first.source_type == 'User'
    end
    false
  end
  
  def trial_credit?
    if credit_note_items.size == 1
      return true if credit_note_items.first.description == 'Trial Credit'
    end
    false
  end

  # There are times when a client needs to be manually given a credit note. Such as when they are
  # mistakenly overcharged by cloud.net
  def self.manually_issue(account, amount, reason, user_that_issued_note)
    credit_note = CreditNote.new account: account
    credit_item = CreditNoteItem.new(
      net_cost: amount.to_f * Invoice::MILLICENTS_IN_DOLLAR,
      tax_cost: 0,
      description: reason, # Shown in 'Product name/Description' field of the Credit Note PDF
      source: user_that_issued_note
    )
    credit_note.credit_note_items = [credit_item]
    credit_note.save!
    account.create_activity(:create_manual_credit, owner: account.user, params: { credit_note: credit_note.id, amount: credit_note.total_cost, issued_by: user_that_issued_note.id })
    
    # Charge unpaid invoices
    unpaid_invoices = account.invoices.not_paid
    ChargeInvoicesTask.new(account.user, unpaid_invoices).process unless unpaid_invoices.empty?
  end
  
  def self.trial_issue(account, card)
    # Auth $1 on the card to verify card before issuing trial credit
    amount = Invoice.milli_to_cents(100_000)
    charge = Payments.new.auth_charge(account.gateway_id, card.processor_token, amount)
    return unless charge[:charge_id]
    
    account.create_activity :auth_charge, owner: account.user, params: { card: card.id, amount: amount, charge_id: charge[:charge_id] }
    
    credit_note = CreditNote.new account: account
    credit_item = CreditNoteItem.new(
      net_cost: TRIAL_CREDIT * Invoice::MILLICENTS_IN_DOLLAR,
      tax_cost: 0,
      description: 'Trial Credit'
    )
    credit_note.credit_note_items = [credit_item]
    credit_note.save!
    account.create_activity(:create_trial_credit, owner: account.user, params: { credit_note: credit_note.id, amount: credit_note.total_cost })
    Analytics.track(account.user, event: 'Issued trial credit', properties: { credit_note: credit_note.id, amount: Invoice.pretty_total(credit_note.total_cost) })
  end
end
