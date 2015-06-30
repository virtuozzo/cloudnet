class CreateUptimes < ActiveRecord::Migration
  def change
    create_table :uptimes do |t|
      t.integer :avgresponse
      t.integer :downtime
      t.datetime :starttime
      t.integer :unmonitored
      t.integer :uptime
      t.references :location, index: true

      t.timestamps null: false
    end
    add_index :uptimes, :starttime
    add_foreign_key :uptimes, :locations
  end
end
