class SendAdminFinancials
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform(type, *args)
    send(type.to_sym, *args)
  end

  def daily
    time = Time.now.yesterday.beginning_of_day
    date_str = time.strftime("#{ActiveSupport::Inflector.ordinalize(time.day)} %B %Y")

    signups        = scope(User, time).to_a.count
    invoice_totals = scope(Invoice, time).to_a.sum(&:total_cost)
    wallet_charges = scope(Charge, time).where('source_type = ? OR source_type = ?', 'CreditNote', 'PaymentReceipt').to_a.sum(&:amount)
    cc_charges = scope(PaymentReceipt, time).where(pay_source: :billing_card).to_a.sum(&:net_cost)
    paypal_charges = scope(PaymentReceipt, time).where(pay_source: :paypal).to_a.sum(&:net_cost)
    manual_credits = scope(CreditNote, time).to_a.sum(&:manual_credits_total_cost)
    trial_credits  = scope(CreditNote, time).to_a.sum(&:trial_credits_total_cost)

    data = {
      date: date_str,
      signups: signups,
      invoices: invoice_totals,
      wallet_charges: wallet_charges,
      cc_charges: cc_charges,
      paypal_charges: paypal_charges,
      manual_credits: manual_credits,
      trial_credits: trial_credits
    }

    AdminMailer.financials(data).deliver_now
  end

  def monthly_csv
    start_date = (Date.today - 1.month).beginning_of_month.beginning_of_day
    end_date   = Date.today.beginning_of_month.beginning_of_day

    AdminMailer.monthly_csv(start_date, end_date).deliver_now
  end

  def periodic_csv(start_date, end_date, report, admin_id)
    start_date = Date.strptime start_date, '%Y-%m-%d'
    end_date   = Date.strptime end_date, '%Y-%m-%d'

    AdminMailer.periodic_csv(start_date, end_date, report, admin_id).deliver_now
  end

  # List of all servers and their market cost vs selling price
  def cost_analysis
    AdminMailer.cost_analysis.deliver_now
  end

  def scope(klass, time)
    klass.where('created_at > ? AND created_at < ?', time.beginning_of_day, time.end_of_day)
  end
end
