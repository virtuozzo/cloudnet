class AddDeletedAtToServerAddons < ActiveRecord::Migration
  def change
    add_column :server_addons, :deleted_at, :datetime
  end
end
