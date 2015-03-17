class RemoveBwipFromPackages < ActiveRecord::Migration
  def change
    remove_column :packages, :ip_addresses, :integer
    remove_column :packages, :bandwidth, :integer
  end
end
