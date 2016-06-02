require 'csv'

class GenerateFinanceReport < BaseTask
  def initialize(start_date, end_date)
    @start = start_date.beginning_of_day
    @end   = end_date.end_of_day
  end

  def account_report
    columns = %w(account_id account_email account_full_name invoice_day created_at vat_number address1 address2 city region postal country cardholder_name currency invoice_total invoice_net_total invoice_vat_total credit_total credit_net_total credit_vat_total manual_credit_total trial_credit_total unpaid_balance credit_balance wallet_balance)

    CSV.generate do |csv|
      csv << columns
      User.all.select { |u| !u.account.nil? }.each { |user| csv << account_user_row(user) }
    end
  end

  def transaction_report
    columns = %w(account_id account_email account_full_name type state item_id created_at source transaction_id net_cost tax_cost total_cost remaining_cost card_charges_total credit_note_charges_total payment_receipt_charges_total)

    CSV.generate do |csv|
      csv << columns
      User.all.select { |u| !u.account.nil? }.each { |user| transaction_user_rows(user).each { |r| csv << r } }
    end
  end

  def charge_report
    columns = %w(account_id item_id created_at source_type source_metadata amount reference)

    CSV.generate do |csv|
      csv << columns
      User.all.select { |u| !u.account.nil? }.each { |user| charges_user_rows(user).each { |r| csv << r } }
    end
  end

  private

  def account_user_row(user)
    account      = user.account
    billing_card = account.primary_billing_card

    row = [account.id, user.email, user.full_name, account.invoice_day, account.created_at, account.vat_number]

    if billing_card.present?
      row.concat([billing_card.address1, billing_card.address2, billing_card.city,
                  billing_card.region, billing_card.postal, billing_card.country,
                  billing_card.cardholder])
    else
      row.concat([''] * 7)
    end

    row.concat(['USD'])
    row.concat(invoice_total(account))
    row.concat(credit_note_total(account))
    row << Invoice.pretty_total(account.remaining_invoice_balance, '')
    row << Invoice.pretty_total(account.wallet_balance, '')
    row << Invoice.pretty_total(account.remaining_balance, '')
  end

  def transaction_user_rows(user)
    account = user.account
    invoices = account.invoices.where('created_at >= ? AND created_at <= ?', @start, @end).to_a
    credit_notes = account.credit_notes.where('created_at >= ? AND created_at <= ?', @start, @end).to_a
    payment_receipts = account.payment_receipts.where('created_at >= ? AND created_at <= ?', @start, @end).to_a
    all = invoices + credit_notes + payment_receipts
    all.sort! { |a, b| a.created_at <=> b.created_at }

    all.map do |item|
      row = [account.id, user.email, user.full_name]
      row.concat [item.class.to_s.downcase, item.state.to_s, item.number, item.created_at]

      if item.is_a?(Invoice)
        row.concat [''] * 2
        row.concat [Invoice.pretty_total(item.net_cost, ''),
                    Invoice.pretty_total(item.tax_cost, ''),
                    Invoice.pretty_total(item.total_cost, ''),
                    Invoice.pretty_total(item.remaining_cost, '')]
        card_charges = item.charges.where(source_type: 'BillingCard').where('created_at >= ? AND created_at <= ?', @start, @end).to_a.sum(&:amount)
        credit_charges = item.charges.where(source_type: 'CreditNote').where('created_at >= ? AND created_at <= ?', @start, @end).to_a.sum(&:amount)
        payment_receipt_charges = item.charges.where(source_type: 'PaymentReceipt').where('created_at >= ? AND created_at <= ?', @start, @end).to_a.sum(&:amount)
        row.concat [Invoice.pretty_total(card_charges, ''), Invoice.pretty_total(credit_charges, ''), Invoice.pretty_total(payment_receipt_charges, '')]
      elsif item.is_a?(CreditNote)
        row.concat [''] * 2
        row.concat [Invoice.pretty_total(-item.net_cost, ''),
                    Invoice.pretty_total(-item.tax_cost, ''),
                    Invoice.pretty_total(-item.total_cost, ''),
                    Invoice.pretty_total(-item.remaining_cost, '')]
        row.concat [''] * 3
      elsif item.is_a?(PaymentReceipt)
        row.concat [item.pay_source,
                    item.reference,
                    Invoice.pretty_total(-item.net_cost, ''),
                    0,
                    Invoice.pretty_total(-item.net_cost, ''),
                    Invoice.pretty_total(-item.remaining_cost, '')]
        row.concat [''] * 3
      end

      row
    end
  end

  def charges_user_rows(user)
    account = user.account
    invoices = account.invoices.select('id').map(&:id)
    charges = Charge.where('created_at >= ? AND created_at <= ?', @start, @end).where(invoice_id: invoices.to_a)

    charges.map do |charge|
      row = [account.id]
      row.concat [Invoice.find(charge.invoice_id).number, charge.created_at, charge.source_type.downcase]

      source = charge.source
      if source.is_a?(BillingCard)
        row << "#{source.card_type} / #{source.last4}"
      elsif source.is_a?(CreditNote)
        row << "Credit Note #{source.number}"
      elsif source.is_a?(PaymentReceipt)
        row << "Payment Receipt #{source.receipt_number}"
      end

      row << Invoice.pretty_total(charge.amount, '')
      row << charge.reference

      row
    end
  end

  def invoice_total(account)
    invoices = account.invoices.where('created_at >= ? AND created_at <= ?', @start, @end).to_a
    [Invoice.pretty_total(invoices.sum(&:total_cost), ''),
     Invoice.pretty_total(invoices.sum(&:net_cost), ''),
     Invoice.pretty_total(invoices.sum(&:tax_cost), '')]
  end

  def credit_note_total(account)
    credit_notes = account.credit_notes.where('created_at >= ? AND created_at <= ?', @start, @end).to_a
    [Invoice.pretty_total(credit_notes.sum(&:total_cost), ''),
     Invoice.pretty_total(credit_notes.sum(&:net_cost), ''),
     Invoice.pretty_total(credit_notes.sum(&:tax_cost), ''),
     Invoice.pretty_total(credit_notes.sum(&:manual_credits_total_cost), ''),
     Invoice.pretty_total(credit_notes.sum(&:trial_credits_total_cost), '')]
  end
end
