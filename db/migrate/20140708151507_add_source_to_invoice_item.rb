class AddSourceToInvoiceItem < ActiveRecord::Migration
  def change
    add_column :invoice_items, :source_id, :integer
    add_column :invoice_items, :source_type, :string
  end
end
