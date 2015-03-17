class AddRemoveInvoicingColumns < ActiveRecord::Migration
  def change
    remove_column :invoices, :tax_cost, :integer, default: 0
    remove_column :invoices, :net_total_cost, :integer, default: 0

    remove_column :invoice_items, :total_cost, :integer
    remove_column :invoice_items, :tax_code, :string
    remove_column :invoice_subitems, :total_cost, :integer

    add_column :invoice_items, :net_cost, :integer
    add_column :invoice_items, :tax_cost, :integer
    add_column :invoice_subitems, :net_cost, :integer
    add_column :invoice_subitems, :tax_cost, :integer
  end
end
