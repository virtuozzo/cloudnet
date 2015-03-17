class AddExpiryMonthAndYearToBillingCard < ActiveRecord::Migration
  def change
    add_column :billing_cards, :expiry_month, :string
    add_column :billing_cards, :expiry_year, :string
  end
end
