class CreateApiKeys < ActiveRecord::Migration
  def change
    create_table :api_keys do |t|
      t.string :title, null: false
      t.string :key, null: false
      t.references :user, index: true
      t.boolean :active, null: false, default: true

      t.timestamps null: false
      t.datetime :deleted_at
    end
    add_foreign_key :api_keys, :users
    add_index :api_keys, ["key"], name: "index_api_keys_on_key", unique: true
  end
end
