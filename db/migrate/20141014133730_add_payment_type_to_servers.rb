class AddPaymentTypeToServers < ActiveRecord::Migration
  def change
    add_column :servers, :payment_type, :string, default: 'prepaid'
  end
end
