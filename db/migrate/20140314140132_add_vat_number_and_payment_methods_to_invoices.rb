class AddVatNumberAndPaymentMethodsToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :vat_number, :string
    add_column :invoices, :charged_amount, :integer
    add_column :invoices, :credit_amount_used, :integer
  end
end
