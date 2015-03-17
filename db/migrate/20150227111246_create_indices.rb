class CreateIndices < ActiveRecord::Migration
  def change
    create_table :indices do |t|
      t.integer :index_cpu, default: 0
      t.integer :index_iops, default: 0
      t.integer :index_bandwidth, default: 0
      t.float :index_uptime, default: 0.0
      t.references :location, index: true

      t.timestamps null: false
    end
    add_foreign_key :indices, :locations
    add_index :indices, [:created_at, :location_id]
  end
end
