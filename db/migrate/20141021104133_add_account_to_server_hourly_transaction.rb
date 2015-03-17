class AddAccountToServerHourlyTransaction < ActiveRecord::Migration
  def change
    add_reference :server_hourly_transactions, :account, index: true
  end
end
