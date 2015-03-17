class AddVatNumberAndBillingCountryToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :vat_number, :string
    # add_column :accounts, :billing_country, :string
  end
end
