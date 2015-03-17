class AddMetadataToInvoiceItems < ActiveRecord::Migration
  def change
    add_column :invoice_items, :metadata, :string
  end
end
