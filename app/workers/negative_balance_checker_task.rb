# Check if a user has negative balance and warn that their servers will be destroyed soon
class NegativeBalanceCheckerTask
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    User.all.each do |user|
      if user.account.remaining_balance > 0
        NegativeBalanceMailer.warning_email(user).deliver_now
      end
    end
  end
end
