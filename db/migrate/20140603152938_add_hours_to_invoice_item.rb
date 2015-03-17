class AddHoursToInvoiceItem < ActiveRecord::Migration
  def change
    add_column :invoice_items, :hours, :integer, default: 0
    add_column :invoice_subitems, :hours, :integer, default: 0
  end
end
