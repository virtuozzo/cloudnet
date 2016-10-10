class AddFaultReportedAtToServers < ActiveRecord::Migration
  def change
    add_column :servers, :fault_reported_at, :datetime
  end
end
