class AddProvisionedAtToServer < ActiveRecord::Migration
  def change
    add_column :servers, :provisioned_at, :datetime
  end
end
