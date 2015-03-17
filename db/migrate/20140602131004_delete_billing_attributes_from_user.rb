class DeleteBillingAttributesFromUser < ActiveRecord::Migration
  def change
    remove_column :users, :payment_token, :string
    remove_column :users, :balance, :integer
    remove_column :users, :billing_date, :datetime
    remove_column :users, :billing_day, :integer
    remove_column :users, :allowed_overdraft, :integer
  end
end
