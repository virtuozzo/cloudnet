class AddVcdFieldsToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :vdc_id, :string
    add_column :locations, :vcd_network_id, :string
    add_column :locations, :vcd_hd_policy, :string
  end
end
