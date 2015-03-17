class AddDuplicateToServerHourlyTransaction < ActiveRecord::Migration
  def change
    add_column :server_hourly_transactions, :duplicate, :boolean, default: false
  end
end
