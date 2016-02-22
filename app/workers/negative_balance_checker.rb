# Check if a user has negative balance and warn that the servers will be destroyed soon
class NegativeBalanceChecker
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    User.where(suspended: false).each { |user| check_user(user) }
  end
  
  def check_user(user)
    if user.account.remaining_balance > 100_000
      user.act_for_negative_balance
    else
      user.clear_unpaid_notifications('balance is correct')
    end
  end
end
