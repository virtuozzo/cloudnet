class AddMaxmindExemptToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :maxmind_exempt, :boolean, default: false
  end
end
