class CreatePaymentReceipts < ActiveRecord::Migration
  def change
    create_table :payment_receipts do |t|
      t.integer 'account_id'
      t.integer 'remaining_cost',  limit: 8
      t.integer 'net_cost',       limit: 8
      t.string 'description'
      t.text 'metadata',       limit: 255
      t.integer 'sequential_id'
      t.string 'state'
      t.text 'billing_address', limit: 255
      t.string 'authorization_hash'
      t.timestamps
    end
  end
end
