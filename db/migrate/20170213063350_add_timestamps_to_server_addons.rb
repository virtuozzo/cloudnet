class AddTimestampsToServerAddons < ActiveRecord::Migration
  def change
    add_column :server_addons, :notified_at, :datetime
    add_column :server_addons, :processed_at, :datetime
  end
end
