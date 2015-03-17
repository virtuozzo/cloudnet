class AddStepsToWizards < ActiveRecord::Migration
  def change
    add_column :wizards, :os_distro_id, :integer
    add_column :wizards, :template_id, :integer
    add_column :wizards, :memory, :integer
    add_column :wizards, :cpus, :integer
    add_column :wizards, :disk, :integer
    add_column :wizards, :bandwidth, :integer
    add_column :wizards, :card_id, :integer
  end
end
