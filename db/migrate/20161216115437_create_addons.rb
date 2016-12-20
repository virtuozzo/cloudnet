class CreateAddons < ActiveRecord::Migration
  def change
    create_table :addons do |t|
      t.string :name
      t.text :description
      t.decimal :price, default: 0.0
      t.string :task
      t.boolean :hidden, default: false
      t.boolean :request_support, default: false

      t.timestamps null: false
    end
  end
end
