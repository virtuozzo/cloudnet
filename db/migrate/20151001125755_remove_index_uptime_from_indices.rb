class RemoveIndexUptimeFromIndices < ActiveRecord::Migration
  def change
    remove_column :indices, :index_uptime, :float
  end
end
