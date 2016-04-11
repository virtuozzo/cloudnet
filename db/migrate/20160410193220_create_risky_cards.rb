class CreateRiskyCards < ActiveRecord::Migration
  def change
    create_table :risky_cards do |t|
      t.string :fingerprint
      t.references :account, index: true

      t.timestamps null: false
      t.datetime :deleted_at
    end
  end
end
