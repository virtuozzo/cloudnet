class ChargeUnpaidInvoices
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    Account.find_each do |account|
      user = account.user
      unpaid = account.invoices.not_paid

      begin
        ChargeInvoicesTask.new(user, unpaid).process unless unpaid.empty?
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'ChargeUnpaidInvoices' })
      end
    end
  end
end
