class DefaultPackagesForLocations < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        Location.find_each do |l|
          Package.create(location: l, memory: 512, cpu: 1, disk: 10, bw: 10, ip_address: 1)
          Package.create(location: l, memory: 768, cpu: 1, disk: 15, bw: 20, ip_address: 1)
          Package.create(location: l, memory: 1024, cpu: 2, disk: 20, bw: 30, ip_address: 1)
        end
      end
    end
  end
end
