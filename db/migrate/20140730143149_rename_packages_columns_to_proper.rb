class RenamePackagesColumnsToProper < ActiveRecord::Migration
  def change
    rename_column :packages, :cpu, :cpus
    rename_column :packages, :disk, :disk_size
    rename_column :packages, :bw, :bandwidth
    rename_column :packages, :ip_address, :ip_addresses
  end
end
