class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.boolean :paid, default: false
      t.string :charge
      t.references :user, index: true

      t.timestamps
    end
  end
end
