class ChangeDescriptionToTransactionId < ActiveRecord::Migration
  def change
    rename_column :payment_receipts, :description, :reference
    remove_column :payment_receipts, :authorization_hash
  end
end
