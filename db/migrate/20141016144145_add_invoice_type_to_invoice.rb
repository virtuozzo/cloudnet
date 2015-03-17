class AddInvoiceTypeToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :invoice_type, :string
  end
end
