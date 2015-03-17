class AddDeletedAtToBillingCards < ActiveRecord::Migration
  def change
    add_column :billing_cards, :deleted_at, :datetime
  end
end
