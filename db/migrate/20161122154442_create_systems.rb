class CreateSystems < ActiveRecord::Migration
  def change
    create_table :systems do |t|
      t.string :key, null: false
      t.string :value, null: false

      t.timestamps null: false
    end

    add_index :systems, :key, unique: true
  end
end
