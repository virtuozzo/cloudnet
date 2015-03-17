class AddOpenStatusToInvoiceItems < ActiveRecord::Migration
  def change
    add_column :invoice_items, :open, :boolean, default: true
  end
end
