class RemoveColumnsFromInvoiceItem < ActiveRecord::Migration
  def change
    remove_column :invoice_items, :hours, :integer
    remove_column :invoice_items, :unit_cost, :integer
    remove_column :invoice_items, :units, :integer
  end
end
