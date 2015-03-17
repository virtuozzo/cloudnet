class AddStartAndEndDateToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :start_date, :date
    add_column :invoices, :end_date, :date
  end
end
