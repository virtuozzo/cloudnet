class CreateInvoiceItems < ActiveRecord::Migration
  def change
    create_table :invoice_items do |t|
      t.references :invoice, index: true
      t.references :server, index: true
      t.string :type
      t.datetime :start_date
      t.datetime :end_date
      t.integer :unit_cost
      t.integer :units

      t.timestamps
    end
  end
end
