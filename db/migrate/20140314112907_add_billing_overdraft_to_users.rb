class AddBillingOverdraftToUsers < ActiveRecord::Migration
  def change
    add_column :users, :allowed_overdraft, :integer
  end
end
