class SendAdminFinancials
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform(type)
    send(type.to_sym)
  end

  def daily
    time = Time.now.yesterday.beginning_of_day
    date_str = time.strftime("#{ActiveSupport::Inflector.ordinalize(time.day)} %B %Y")

    signups        = scope(User, time).to_a.count
    invoice_totals = scope(Invoice, time).to_a.sum(&:total_cost)
    credit_totals  = scope(CreditNote, time).to_a.sum(&:total_cost)
    charges        = scope(Charge, time).where(source_type: 'BillingCard').to_a.sum(&:amount)
    payg_cc_charges = scope(PaymentReceipt, time).where(pay_source: :billing_card).to_a.sum(&:net_cost)
    payg_paypal_charges = scope(PaymentReceipt, time).where(pay_source: :paypal).to_a.sum(&:net_cost)

    data = {
      date: date_str,
      signups: signups,
      invoices: invoice_totals,
      credits: credit_totals,
      charges: charges,
      payg_cc_charges: payg_cc_charges,
      payg_paypal_charges: payg_paypal_charges
    }

    AdminMailer.financials(data).deliver_now
  end

  def monthly_csv
    start_date = (Date.today - 1.month).beginning_of_month.beginning_of_day
    end_date   = Date.today.beginning_of_month.beginning_of_day

    AdminMailer.monthly_csv(start_date, end_date).deliver_now
  end

  def scope(klass, time)
    klass.where('created_at > ? AND created_at < ?', time.beginning_of_day, time.end_of_day)
  end
end
