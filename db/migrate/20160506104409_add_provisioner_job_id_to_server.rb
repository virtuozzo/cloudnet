class AddProvisionerJobIdToServer < ActiveRecord::Migration
  def change
    add_column :servers, :provisioner_job_id, :string
  end
end
