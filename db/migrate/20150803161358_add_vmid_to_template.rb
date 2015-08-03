class AddVmidToTemplate < ActiveRecord::Migration
  def change
    add_column :templates, :vmid, :string
  end
end
