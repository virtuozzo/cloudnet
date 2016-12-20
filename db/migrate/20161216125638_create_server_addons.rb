class CreateServerAddons < ActiveRecord::Migration
  def change
    create_table :server_addons do |t|
      t.references :addon, index: true
      t.references :server, index: true

      t.timestamps null: false
    end
    
    add_foreign_key :server_addons, :addons
    add_foreign_key :server_addons, :servers
  end
end
