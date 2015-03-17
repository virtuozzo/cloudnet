class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :gateway_id
      t.date :invoice_start
      t.integer :invoice_day
      t.references :user, index: true

      t.timestamps
    end
  end
end
