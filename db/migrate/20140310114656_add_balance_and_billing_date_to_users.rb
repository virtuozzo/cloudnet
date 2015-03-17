class AddBalanceAndBillingDateToUsers < ActiveRecord::Migration
  def change
    add_column :users, :balance, :integer
    add_column :users, :billing_date, :date
  end
end
