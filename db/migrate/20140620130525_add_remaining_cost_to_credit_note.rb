class AddRemainingCostToCreditNote < ActiveRecord::Migration
  def change
    add_column :credit_notes, :remaining_cost, :integer
  end
end
