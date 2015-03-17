class AddTaxCodeToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :tax_code, :string
  end
end
