class AddIndexToTables < ActiveRecord::Migration
  def change
    add_index :dns_zones, :domain_id
    add_index :users, :onapp_user
    add_index :servers, :ip_address
    add_index :templates, :identifier
    add_index :locations, :country
    add_index :server_backups, :identifier
  end
end
