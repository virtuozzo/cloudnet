class AddNetTotalCostToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :net_total_cost, :integer
  end
end
