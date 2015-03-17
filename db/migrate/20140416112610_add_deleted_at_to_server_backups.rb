class AddDeletedAtToServerBackups < ActiveRecord::Migration
  def change
    add_column :server_backups, :deleted_at, :datetime
  end
end
