class AddDeletedAtToPaymentReceipts < ActiveRecord::Migration
  def change
    add_column :payment_receipts, :deleted_at, :datetime
  end
end
