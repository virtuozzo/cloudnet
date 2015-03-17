class AddSequentialIdToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :sequential_id, :integer
  end
end
