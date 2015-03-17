class AddBilledUntilDateToInvoiceItems < ActiveRecord::Migration
  def change
    add_column :invoice_items, :billed_until, :datetime
  end
end
