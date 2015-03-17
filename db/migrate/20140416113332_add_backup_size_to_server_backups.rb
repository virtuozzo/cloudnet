class AddBackupSizeToServerBackups < ActiveRecord::Migration
  def change
    add_column :server_backups, :backup_size, :integer
  end
end
