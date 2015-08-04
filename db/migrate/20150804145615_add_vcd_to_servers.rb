class AddVcdToServers < ActiveRecord::Migration
  def change
    add_reference :servers, :vcd, index: true
    add_foreign_key :servers, :vcds
  end
end
