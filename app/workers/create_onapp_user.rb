class CreateOnappUser
  include Sidekiq::Worker
  sidekiq_options queue: 'create_onapp_user'

  def perform(user_id)
    UserTasks.new.perform(:create, user_id)
  end
end
