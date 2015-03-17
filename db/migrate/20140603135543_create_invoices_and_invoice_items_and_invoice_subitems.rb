class CreateInvoicesAndInvoiceItemsAndInvoiceSubitems < ActiveRecord::Migration
  def change
    drop_table :invoices, {}
    drop_table :invoice_items, {}

    create_table :invoices do |t|
      t.boolean :paid, default: false
      t.references :account, index: true
      t.boolean :vat_excempt
      t.string :vat_number
      t.timestamps
      t.datetime :deleted_at
    end

    create_table :invoice_items do |t|
      t.string :description
      t.integer :units, default: 0
      t.integer :unit_cost, default: 0
      t.integer :total_cost
      t.string :tax_code
      t.boolean :subitems
      t.references :invoice, index: true
      t.timestamps
      t.datetime :deleted_at
    end

    create_table :invoice_subitems do |t|
      t.string :description
      t.integer :units, default: 0
      t.integer :unit_cost, default: 0
      t.integer :total_cost
      t.references :invoice_item, index: true
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
