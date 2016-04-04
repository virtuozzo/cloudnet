class AddFreeBillingBandwidthToServers < ActiveRecord::Migration
  def change
    add_column :servers, :free_billing_bandwidth, :integer, default: 0
  end
end
