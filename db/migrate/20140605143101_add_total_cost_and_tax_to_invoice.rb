class AddTotalCostAndTaxToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :tax_cost, :integer, default: 0
  end
end
