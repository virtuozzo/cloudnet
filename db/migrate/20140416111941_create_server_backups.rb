class CreateServerBackups < ActiveRecord::Migration
  def change
    create_table :server_backups do |t|
      t.boolean :built, default: false
      t.datetime :built_at
      t.datetime :backup_created
      t.string :identifier
      t.boolean :locked
      t.integer :disk_id
      t.integer :min_disk_size
      t.integer :min_memory_size
      t.integer :backup_id
      t.references :server

      t.timestamps
    end
  end
end
