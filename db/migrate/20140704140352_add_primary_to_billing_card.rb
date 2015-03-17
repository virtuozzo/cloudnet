class AddPrimaryToBillingCard < ActiveRecord::Migration
  def change
    add_column :billing_cards, :primary, :boolean, default: false
  end
end
