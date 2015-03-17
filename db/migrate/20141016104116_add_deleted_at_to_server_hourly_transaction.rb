class AddDeletedAtToServerHourlyTransaction < ActiveRecord::Migration
  def change
    add_column :server_hourly_transactions, :deleted_at, :datetime
  end
end
