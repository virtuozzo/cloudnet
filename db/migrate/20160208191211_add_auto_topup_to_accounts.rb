class AddAutoTopupToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :auto_topup, :boolean, default: true
  end
end
