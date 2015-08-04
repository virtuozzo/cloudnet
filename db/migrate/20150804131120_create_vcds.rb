class CreateVcds < ActiveRecord::Migration
  def change
    create_table :vcds do |t|
      t.string :identifier
      t.string :name
      t.string :status
      t.references :user, index: true
      t.references :template, index: true

      t.timestamps null: false
    end
    add_foreign_key :vcds, :users
    add_foreign_key :vcds, :templates
  end
end
