class RemoveVatExcemptColumnFromInvoice < ActiveRecord::Migration
  def change
    remove_column :invoices, :vat_excempt, :boolean
  end
end
