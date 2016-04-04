class AutoBilling
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform(date = Date.today)
    Account.invoice_day(date).find_each do |account|
      user    = account.user
      servers = user.servers.prepaid.where('created_at < ?', account.past_invoice_due)

      begin
        AutomatedBillingTask.new(user, servers, Account::HOURS_MAX).process unless servers.empty?
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'AutoBilling' })
      end
    end
  end
end
