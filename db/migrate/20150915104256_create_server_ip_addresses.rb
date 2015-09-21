class CreateServerIpAddresses < ActiveRecord::Migration
  def change
    create_table :server_ip_addresses do |t|
      t.string :address
      t.string :netmask
      t.string :network
      t.string :broadcast
      t.string :gateway
      t.references :server, index: true
      t.string :identifier
      t.boolean :primary, default: false

      t.timestamps null: false
      t.datetime :deleted_at
    end
    add_index :server_ip_addresses, :address
    add_index :server_ip_addresses, :identifier
    add_foreign_key :server_ip_addresses, :servers
  end
end
