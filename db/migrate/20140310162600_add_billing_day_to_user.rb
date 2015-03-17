class AddBillingDayToUser < ActiveRecord::Migration
  def change
    add_column :users, :billing_day, :integer
  end
end
