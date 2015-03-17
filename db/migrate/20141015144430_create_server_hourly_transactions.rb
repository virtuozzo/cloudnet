class CreateServerHourlyTransactions < ActiveRecord::Migration
  def change
    create_table :server_hourly_transactions do |t|
      t.references :server, index: true
      t.integer :net_cost
      t.text :metadata
      t.references :coupon, index: true

      t.timestamps
    end
  end
end
