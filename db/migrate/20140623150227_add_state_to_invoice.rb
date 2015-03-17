class AddStateToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :state, :string, default: 'unpaid'
    remove_column :invoices, :paid, :boolean
  end
end
