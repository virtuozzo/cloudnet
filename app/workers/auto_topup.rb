# Automatically top-up the Wallet of a user with the minimum valid top-up amount as per Payg::VALID_TOP_UP_AMOUNTS
# Conditions to be met for the top-up to be made:
#       * Have atleast one active servers
#       * Have atleast one processable billing card
#       * Have a Wallet balance of less than $2

class AutoTopup
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    Account.where(auto_topup: true).find_each do |account|
      user = account.user
      next unless user.servers.count > 0 && 
                  account.billing_cards.processable.count > 0 && 
                  account.wallet_balance < 200_000
      begin
        task = PaygTopupCardTask.new(account, Payg::VALID_TOP_UP_AMOUNTS.min)
        if task.process
          unpaid_invoices = account.invoices.not_paid
          ChargeInvoicesTask.new(user, unpaid_invoices).process unless unpaid_invoices.empty?
        end
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'AutoTopup' })
      end
    end
  end
end
