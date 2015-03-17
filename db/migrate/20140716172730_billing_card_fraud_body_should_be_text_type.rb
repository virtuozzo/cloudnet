class BillingCardFraudBodyShouldBeTextType < ActiveRecord::Migration
  def change
    change_column :billing_cards, :fraud_body, :text
  end
end
