class CreateTemplates < ActiveRecord::Migration
  def change
    create_table :templates do |t|
      t.string :os_type
      t.string :os_distro
      t.string :identifier
      t.integer :price
      t.string :name
      t.references :location, index: true

      t.timestamps
    end
  end
end
