class RemoveSubitemsFromInvoiceItems < ActiveRecord::Migration
  def change
    remove_column :invoice_items, :subitems, :boolean
  end
end
