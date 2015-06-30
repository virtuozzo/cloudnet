class AddPingdomToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :pingdom_id, :integer
    add_column :locations, :pingdom_name, :string
  end
end
