class AddCardTypeToBillingCards < ActiveRecord::Migration
  def change
    add_column :billing_cards, :card_type, :string
  end
end
