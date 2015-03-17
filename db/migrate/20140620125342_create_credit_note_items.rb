class CreateCreditNoteItems < ActiveRecord::Migration
  def change
    create_table :credit_note_items do |t|
      t.string :description
      t.integer :units
      t.integer :unit_cost
      t.integer :hours
      t.integer :net_cost
      t.integer :tax_cost
      t.datetime :deleted_at
      t.references :credit_note, index: true

      t.timestamps
    end
  end
end
