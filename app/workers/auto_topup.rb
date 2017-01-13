# Automatically top-up the Wallet of a user with the minimum top-up amount as per Payg::MIN_AUTO_TOP_UP_AMOUNT
# Conditions to be met for the top-up to be made:
#       * Have atleast one active servers
#       * Have atleast one processable billing card
#       * Have a Wallet balance of less than $2
#       * Does not have a 100% discounted active coupon code
#       * Is not flagged for fraud

class AutoTopup
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    return unless PAYMENTS[:stripe][:api_key].present?
    Account.where(auto_topup: true).find_each do |account|
      user = account.user
      next unless user.servers.count > 0 &&
                  account.billing_cards.processable.count > 0 &&
                  account.wallet_balance < 200_000
      next if account.coupon && account.coupon.percentage == 100
      next unless account.fraud_safe?
      begin
        current_balance = account.remaining_balance
        topup = perform_topup(account)
        account.reload
        account.create_activity :auto_topup, owner: user, params: { current_balance: current_balance, topup_amount: Payg::MIN_AUTO_TOP_UP_AMOUNT * Invoice::MILLICENTS_IN_DOLLAR, new_balance: account.wallet_balance, success: topup }
        user_info = { email: user.email, full_name: user.full_name }
        NotifyUsersMailer.delay.notify_auto_topup(user_info, topup)
        charge_unpaid_invoices(account) if topup
        account.expire_wallet_balance
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'AutoTopup' })
      end
    end
  end

  def perform_topup(account)
    task = PaygTopupCardTask.new(account, Payg::MIN_AUTO_TOP_UP_AMOUNT)
    task.process
  end

  def charge_unpaid_invoices(account)
    unpaid_invoices = account.invoices.not_paid
    ChargeInvoicesTask.new(account.user, unpaid_invoices).process unless unpaid_invoices.empty?
  end
end
