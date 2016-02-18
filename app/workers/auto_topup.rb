# Automatically top-up the Wallet of a user with the minimum valid top-up amount as per Payg::VALID_TOP_UP_AMOUNTS
# Conditions to be met for the top-up to be made:
#       * Have atleast one active servers
#       * Have atleast one processable billing card
#       * Have a Wallet balance of less than $2
#       * Does not have a 100% discounted active coupon code

class AutoTopup
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    Account.where(auto_topup: true).find_each do |account|
      user = account.user
      next unless user.servers.count > 0 && 
                  account.billing_cards.processable.count > 0 && 
                  account.wallet_balance < 200_000
      next if account.coupon && account.coupon.percentage == 100
      begin
        task = PaygTopupCardTask.new(account, Payg::VALID_TOP_UP_AMOUNTS.min)
        user_info = { email: user.email, full_name: user.full_name }
        if task.process
          NotifyUsersMailer.delay.notify_auto_topup(user_info, true)
          unpaid_invoices = account.invoices.not_paid
          ChargeInvoicesTask.new(user, unpaid_invoices).process unless unpaid_invoices.empty?
        else
          NotifyUsersMailer.delay.notify_auto_topup(user_info, false)
        end
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'AutoTopup' })
      end
    end
  end
end
