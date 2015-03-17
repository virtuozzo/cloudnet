class AddTransactionCappedToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :transactions_capped, :boolean, default: true

    reversible do |dir|
      dir.up do
        Invoice.where(invoice_type: :payg).all.each do |invoice|
          invoice.update(transactions_capped: false)
        end
      end
    end
  end
end
