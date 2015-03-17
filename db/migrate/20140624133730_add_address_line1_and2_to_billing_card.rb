class AddAddressLine1And2ToBillingCard < ActiveRecord::Migration
  def change
    add_column :billing_cards, :address1, :string
    add_column :billing_cards, :address2, :string
  end
end
