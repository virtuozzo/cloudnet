class RemoveUnitTypeAndAddItemTypeToInvoiceSubitems < ActiveRecord::Migration
  def change
    remove_column :invoice_subitems, :unit_type, :string
    add_column :invoice_subitems, :item_type, :string
  end
end
