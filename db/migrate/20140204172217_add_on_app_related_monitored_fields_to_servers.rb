class AddOnAppRelatedMonitoredFieldsToServers < ActiveRecord::Migration
  def change
    add_column :servers, :built, :boolean, default: false
    add_column :servers, :locked, :boolean, default: true
    add_column :servers, :suspended, :boolean, default: true

    add_column :servers, :cpus, :integer
    add_column :servers, :hypervisor_id, :integer
    add_column :servers, :root_password, :string
    add_column :servers, :memory, :integer
    add_column :servers, :os, :string
    add_column :servers, :os_distro, :string
    add_column :servers, :remote_access_password, :string
    add_column :servers, :disk_size, :integer
  end
end
