class AddCreditOptionToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :credit, :boolean
  end
end
