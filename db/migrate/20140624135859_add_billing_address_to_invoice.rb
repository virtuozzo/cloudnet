class AddBillingAddressToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :billing_address, :string
  end
end
