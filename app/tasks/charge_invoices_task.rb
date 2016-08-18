class ChargeInvoicesTask < BaseTask
  def initialize(user, invoices, auto_billing = false)
    @user     = user
    @invoices = invoices
    @auto_billing = auto_billing
  end

  def process
    account = @user.account
    card    = account.primary_billing_card

    # First try credit notes
    @invoices.each do |invoice|
      credit_notes = account.credit_notes.with_remaining_cost
      notes_used = CreditNote.charge_account(credit_notes, invoice.remaining_cost)
      account.create_activity :charge_credit_account, owner: @user, params: { notes: notes_used } unless notes_used.empty?
      self.class.create_credit_note_charges(account, invoice, notes_used, @user)
    end

    # We're done if everything is paid off
    @invoices.each(&:reload)
    if Invoice.milli_to_cents(@invoices.to_a.sum(&:remaining_cost)) == 0
      unblock_servers
      @user.account.expire_wallet_balance
      return
    end

    # Now try any cash that's credited in the user's account
    @invoices.each do |invoice|
      payment_receipts = account.payment_receipts.with_remaining_cost
      notes_used = PaymentReceipt.charge_account(payment_receipts, invoice.remaining_cost)
      account.create_activity :charge_payment_account, owner: @user, params: { notes: notes_used } unless notes_used.empty?
      create_payment_receipt_charges(account, invoice, notes_used)
    end
    unblock_servers if @user.account.remaining_balance <= 100_000
    @user.account.expire_wallet_balance
  end
  
  def unblock_servers
    @user.clear_unpaid_notifications("balance is correct")
    @user.refresh_my_servers
  end

  def create_payment_receipt_charges(account, invoice, payment_receipts)
    payment_receipts.each do |k, v|
      source = PaymentReceipt.find(k)
      Charge.create(source: source, invoice: invoice, amount: v)
      account.create_activity :payment_receipt_charge, owner: @user, params: { invoice: invoice.id, amount: v, payment_receipt: k }
    end
    
    invoice.reload

    if Invoice.milli_to_cents(invoice.remaining_cost) > 0 && payment_receipts.present?
      invoice.update(state: :partially_paid)
    elsif Invoice.milli_to_cents(invoice.remaining_cost) <= 0
      invoice.update(state: :paid)
    end
  end

  private

  def charge_primary_card_for_invoices(account, invoices, card)
    remaining_cost = invoices.sum(&:remaining_cost)

    begin
      charge = Payments.new.auth_charge(account.gateway_id, card.processor_token, Invoice.milli_to_cents(remaining_cost))
      account.create_activity :auth_charge, owner: @user, params: { card: card.id, amount: Invoice.milli_to_cents(remaining_cost), charge_id: charge[:charge_id] }
      Payments.new.capture_charge(charge[:charge_id], card_description(invoices))
      account.create_activity :capture_charge, owner: @user, params: { card: card.id, charge_id: charge[:charge_id] }
      create_card_charges_for_invoices(account, invoices, card, charge)
      mark_invoices_as_paid(invoices)
      track_invoice_revenue(remaining_cost)
    rescue Stripe::StripeError => e
      ErrorLogging.new.track_exception(e, extra: { current_user: @user, source: 'AutomatedBillingTask', invoices: invoices, remaining_cost: remaining_cost })
      account.create_activity :auth_charge_failed, owner: @user, params: { card: card.id, amount: Invoice.milli_to_cents(remaining_cost), reason: e.message }
    end
  end

  def self.create_credit_note_charges(account, invoice, credit_notes, user)
    credit_notes.each do |k, v|
      source = CreditNote.find(k)
      Charge.create(source: source, invoice: invoice, amount: v)
      account.create_activity :credit_charge, owner: user, params: { invoice: invoice.id, amount: v, credit_note: k }
    end
    
    invoice.reload

    if Invoice.milli_to_cents(invoice.remaining_cost) > 0 && credit_notes.present?
      invoice.update(state: :partially_paid)
    elsif Invoice.milli_to_cents(invoice.remaining_cost) <= 0
      invoice.update(state: :paid)
    end
  end

  def create_card_charges_for_invoices(account, invoices, card, charge)
    invoices.each do |invoice|
      amount = invoice.remaining_cost
      Charge.create(source: card, invoice: invoice, amount: amount, reference: charge[:charge_id])
      account.create_activity :card_charge, owner: @user, params: { invoice: invoice.id, amount: amount, card: card.id }
    end
  end

  def card_description(invoices)
    "#{ENV['BRAND_NAME']} Invoice(s) #{invoices.map(&:invoice_number).join(', ')}"
  end

  def mark_invoices_as_paid(invoices)
    invoices.each { |invoice| invoice.update(state: :paid) }
  end

  def track_invoice_revenue(remaining_cost)
    Analytics.track(@user, event: 'Generated revenue', properties: { revenue: Invoice.pretty_total(remaining_cost) })
  end
end
