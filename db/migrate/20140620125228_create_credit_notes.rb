class CreateCreditNotes < ActiveRecord::Migration
  def change
    create_table :credit_notes do |t|
      t.references :account, index: true
      t.string :vat_number
      t.boolean :vat_exempt
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
