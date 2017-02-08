class AddWhitelistedToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :whitelisted, :boolean, default: false
  end
end
