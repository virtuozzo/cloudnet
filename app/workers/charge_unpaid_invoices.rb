class ChargeUnpaidInvoices
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    Account.find_each do |account|
      user = account.user
      prepaid = account.invoices.prepaid.not_paid
      payg = account.invoices.payg.not_paid

      begin
        ChargeInvoicesTask.new(user, prepaid).process unless prepaid.empty?
        ChargePaygInvoicesTask.new(user, payg).process unless payg.empty?
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'ChargeUnpaidInvoices' })
      end
    end
  end
end
