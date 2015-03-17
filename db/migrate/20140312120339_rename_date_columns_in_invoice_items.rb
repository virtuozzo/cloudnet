class RenameDateColumnsInInvoiceItems < ActiveRecord::Migration
  def change
    rename_column :invoice_items, :start_date, :start_at
    rename_column :invoice_items, :end_date, :end_at
  end
end
