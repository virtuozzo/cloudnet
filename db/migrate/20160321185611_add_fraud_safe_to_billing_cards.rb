class AddFraudSafeToBillingCards < ActiveRecord::Migration
  def change
    add_column :billing_cards, :fraud_safe, :boolean, default: false
  end
end
