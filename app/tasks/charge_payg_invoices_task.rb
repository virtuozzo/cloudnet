class ChargePaygInvoicesTask < BaseTask
  def initialize(user, invoices, auto_billing = false)
    @user     = user
    @invoices = invoices
    @auto_billing = auto_billing
  end

  def process
    account = @user.account

    @invoices.each do |invoice|
      payment_receipts = account.payment_receipts.with_remaining_cost
      notes_used = PaymentReceipt.charge_account(payment_receipts, invoice.remaining_cost)
      account.create_activity :charge_payment_account, owner: @user, params: { notes: notes_used } unless notes_used.empty?
      create_payment_receipt_charges(account, invoice, notes_used)
    end
  end

  private

  def create_payment_receipt_charges(account, invoice, payment_receipts)
    payment_receipts.each do |k, v|
      source = PaymentReceipt.find(k)
      Charge.create(source: source, invoice: invoice, amount: v)
      account.create_activity :payment_receipt_charge, owner: @user, params: { invoice: invoice.id, amount: v, payment_receipt: k }
    end

    if Invoice.milli_to_cents(invoice.remaining_cost) > 0 && payment_receipts.present?
      invoice.update(state: :partially_paid)
    elsif Invoice.milli_to_cents(invoice.remaining_cost) <= 0
      invoice.update(state: :paid)
    end
  end
end
