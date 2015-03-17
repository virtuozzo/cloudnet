class AddCardholderToBillingCard < ActiveRecord::Migration
  def change
    add_column :billing_cards, :cardholder, :string
  end
end
