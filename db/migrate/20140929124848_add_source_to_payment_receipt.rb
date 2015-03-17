class AddSourceToPaymentReceipt < ActiveRecord::Migration
  def change
    add_column :payment_receipts, :pay_source, :string
  end
end
