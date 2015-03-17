class RemoveInvoiceSubitems < ActiveRecord::Migration
  def change
    drop_table :invoice_subitems
  end
end
