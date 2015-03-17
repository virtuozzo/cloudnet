class CreatePackages < ActiveRecord::Migration
  def change
    create_table :packages do |t|
      t.references :location, index: true
      t.integer :memory
      t.integer :cpu
      t.integer :disk
      t.integer :bw
      t.integer :ip_address

      t.timestamps
    end
  end
end
