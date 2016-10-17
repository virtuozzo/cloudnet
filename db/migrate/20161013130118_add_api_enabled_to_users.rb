class AddApiEnabledToUsers < ActiveRecord::Migration
  def change
    add_column :users, :api_enabled, :boolean, default: true
  end
end
