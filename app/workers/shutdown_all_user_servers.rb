class ShutdownAllUserServers
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find user_id
    NegativeBalanceProtection::Actions::ShutdownAllServers.new(user, 'UserSuspended').perform
  end
end
