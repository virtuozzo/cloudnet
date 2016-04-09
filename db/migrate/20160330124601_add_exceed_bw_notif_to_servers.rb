class AddExceedBwNotifToServers < ActiveRecord::Migration
  def change
    add_column :servers, :exceed_bw_user_notif, :integer, default: 0
    add_column :servers, :exceed_bw_value, :integer, default: 0
    add_column :servers, :exceed_bw_user_last_sent, :datetime
    add_column :servers, :exceed_bw_admin_notif, :integer, default: 0
  end
end
