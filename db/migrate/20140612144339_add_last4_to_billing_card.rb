class AddLast4ToBillingCard < ActiveRecord::Migration
  def change
    add_column :billing_cards, :last4, :string
  end
end
