class CreateKeys < ActiveRecord::Migration
  def change
    create_table :keys do |t|
      t.string :title
      t.text :key
      t.references :user, index: true

      t.timestamps null: false
      t.datetime :deleted_at
    end
    add_foreign_key :keys, :users
  end
end
