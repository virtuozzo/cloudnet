class CreateCharges < ActiveRecord::Migration
  def change
    create_table :charges do |t|
      t.references :invoice, index: true
      t.string :source_type
      t.integer :source_id
      t.integer :amount

      t.timestamps
    end
  end
end
