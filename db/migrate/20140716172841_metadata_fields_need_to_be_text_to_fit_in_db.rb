class MetadataFieldsNeedToBeTextToFitInDb < ActiveRecord::Migration
  def change
    change_column :credit_note_items, :metadata, :text
    change_column :invoice_items, :metadata, :text
    change_column :credit_notes, :billing_address, :text
    change_column :invoices, :billing_address, :text
    change_column :server_usages, :usages, :text
  end
end
