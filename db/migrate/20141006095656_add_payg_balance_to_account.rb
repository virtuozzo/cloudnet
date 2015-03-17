class AddPaygBalanceToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :payg_balance, :integer, default: 0
  end
end
