class AddStateTaxCodeBillingAddressToCreditNotes < ActiveRecord::Migration
  def change
    add_column :credit_notes, :state, :string
    add_column :credit_notes, :tax_code, :string
    add_column :credit_notes, :billing_address, :string
  end
end
