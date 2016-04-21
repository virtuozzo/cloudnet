class PrepareServersCount < ActiveRecord::Migration
  def up
    User.find_each { |user| UserAnalytics::ServerCountUpdater.new(user).update_user }
  end

  def down
    UserServerCount.delete_all
  end
end
