class DockerProvision
  include Sidekiq::Worker
  sidekiq_options unique: true
  sidekiq_options :retry => 5
  attr_reader :server_id, :role
  
  FINAL_STATUS = %w(Failed Done Error Aborted)
  POLLING_TIME = 30.seconds
  
  def perform(server_id, role)
    @server_id = server_id
    @role = role
    
    resp = send_data_to_provisioner
    case resp.status
    when 200..209
      status = wait_for_server_provisioned(resp.body)
      finalize_build(status[:status])
    else 
      handle_task_build_error(resp)
    end
  end
  
  def send_data_to_provisioner
    provision_tasks.create(server_id, role)
  end
  
  def finalize_build(status)
    if status == "Done"
      user_id = Server.find(server_id).user.id
      ServerTasks.new.perform(:refresh_server, user_id, server_id)
    else
      # report error
    end
  end
  
  def wait_for_server_provisioned(job_id)
    status = nil
    loop do
      status = job_status(job_id)
      break if status.nil? || status[:status].in?(FINAL_STATUS)
      sleep POLLING_TIME
    end
    status
  end
  
  def job_status(job_id)
    resp = provision_tasks.status(job_id)
    resp.status == 200 ? JSON.parse(resp.body).symbolize_keys : {status: "Error"}
  end
  
  def handle_task_build_error(resp)
  end
  
  def provision_tasks
    @provision_tasks ||= DockerProvisionerTasks.new
  end
end