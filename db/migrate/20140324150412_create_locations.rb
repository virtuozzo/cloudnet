class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :latitude
      t.string :longitude
      t.string :name
      t.string :country
      t.string :city
      t.integer :memory
      t.integer :disk
      t.integer :cpu
      t.integer :hv_group_id

      t.timestamps
    end
  end
end
