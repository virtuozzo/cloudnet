class MakePricingColumnsBigInt < ActiveRecord::Migration
  def change
    change_column :charges, :amount, :integer, limit: 8

    change_column :credit_note_items, :unit_cost, :integer, limit: 8
    change_column :credit_note_items, :net_cost, :integer, limit: 8
    change_column :credit_note_items, :tax_cost, :integer, limit: 8

    change_column :credit_notes, :remaining_cost, :integer, limit: 8

    change_column :invoice_items, :net_cost, :integer, limit: 8
    change_column :invoice_items, :tax_cost, :integer, limit: 8

    change_column :locations, :price_memory, :integer, limit: 8, default: 0
    change_column :locations, :price_disk, :integer, limit: 8, default: 0
    change_column :locations, :price_cpu, :integer, limit: 8, default: 0
    change_column :locations, :price_bw, :integer, limit: 8, default: 0

    change_column :templates, :price, :integer, limit: 8, default: nil
  end
end
