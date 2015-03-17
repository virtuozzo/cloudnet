class AutoBilling
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform(date = Date.today)
    Account.invoice_day(date).find_each do |account|
      user    = account.user
      prepaid = user.servers.prepaid.where('created_at < ?', account.past_invoice_due)

      payg = user.servers.payg.where('created_at < ?', account.past_invoice_due)
      date_range = account.past_invoice_date_past_months(1.month)..account.past_invoice_date
      payg_deleted = user.servers.only_deleted.payg.where(created_at: date_range)
      payg_merged = payg.concat(payg_deleted)

      begin
        AutomatedBillingTask.new(user, prepaid).process unless prepaid.empty?
        AutomatedPaygBillingTask.new(user, payg_merged).process unless payg_merged.empty?
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'AutoBilling' })
      end
    end
  end
end
