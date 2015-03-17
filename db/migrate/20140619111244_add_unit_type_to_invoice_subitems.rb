class AddUnitTypeToInvoiceSubitems < ActiveRecord::Migration
  def change
    add_column :invoice_subitems, :unit_type, :string
  end
end
