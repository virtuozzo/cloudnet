class AddVatExemptToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :vat_exempt, :boolean
  end
end
