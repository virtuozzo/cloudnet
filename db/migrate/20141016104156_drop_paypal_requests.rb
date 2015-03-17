class DropPaypalRequests < ActiveRecord::Migration
  def change
    drop_table :paypal_requests
  end
end
