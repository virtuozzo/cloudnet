# Check if a user has negative balance and warn that the servers will be destroyed soon
class NegativeBalanceChecker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed
  sidekiq_options :retry => 2

  def perform
    User.find_each { |user| check_user(user) }
  end

  def check_user(user)
    suspended = user.suspended
    user.update_attribute(:suspended, false) if suspended
    if user.account.remaining_balance > 100_000
      user.act_for_negative_balance
      user.add_tags_by_label(:negative_balance)
    else
      user.clear_unpaid_notifications('balance is correct')
      user.remove_tags_by_label(:negative_balance)
    end
  rescue => e
    log_error(e, user)
  ensure
    user.update_attribute(:suspended, true) if suspended
  end

  def log_error(e, user)
    ErrorLogging.new.track_exception(
      e,
      extra: {
        user: user.id,
        source: 'NegativeBalanceChecker',
      }
    )
  end
end
