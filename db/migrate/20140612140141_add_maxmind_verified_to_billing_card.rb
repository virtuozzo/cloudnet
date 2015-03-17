class AddMaxmindVerifiedToBillingCard < ActiveRecord::Migration
  def change
    add_column :billing_cards, :maxmind_verified, :boolean, default: false
  end
end
