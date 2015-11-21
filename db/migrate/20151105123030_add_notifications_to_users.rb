class AddNotificationsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :notif_before_shutdown, :integer, default: 3
    add_column :users, :notif_before_destroy, :integer, default: 21
    add_column :users, :notif_delivered, :integer, default: 0
    add_column :users, :last_notif_email_sent, :datetime
    add_column :users, :admin_destroy_request, :integer, default: 0
  end
end
