class CreatePaypalRequests < ActiveRecord::Migration
  def change
    create_table :paypal_requests do |t|
      t.string :token
      t.references :account

      t.timestamps
    end
  end
end
