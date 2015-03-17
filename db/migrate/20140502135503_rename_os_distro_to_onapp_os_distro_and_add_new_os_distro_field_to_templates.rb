class RenameOsDistroToOnappOsDistroAndAddNewOsDistroFieldToTemplates < ActiveRecord::Migration
  def change
    rename_column :templates, :os_distro, :onapp_os_distro
    add_column :templates, :os_distro, :string

    reversible do |dir|
      dir.up do
        Template.all.each do |template|
          distro = Template.distro_name(template.onapp_os_distro, template.name, template.os_type)
          template.update(os_distro: distro)
        end
      end
    end
  end
end
