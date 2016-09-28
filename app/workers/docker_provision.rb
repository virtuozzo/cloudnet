class DockerProvision
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed
  sidekiq_options :retry => 5
  attr_reader :server, :role, :job_id
  
  FINAL_STATUS = %w(Failed Done Error Aborted)
  POLLING_TIME = 30.seconds
  
  class ProvisionerError < StandardError; end
    
  def perform(server_id, role)
    @server = Server.find(server_id)
    @role = role
    @job_id = nil
    
    resp = send_data_to_provisioner
    
    case resp.status
    when 200..209
      @job_id = resp.body
      save_job_id
      status = wait_for_server_provisioned[:status]
      raise(ProvisionerError, status) unless status == "Done"
      set_provision_time
    else 
      raise(ProvisionerError, resp.status)
    end
    
  rescue => e
    Rails.logger.warn "Provisioner of #{role} for server #{server_id} failed"
    ErrorLogging.new.track_exception(e, extra: prov_error_params)
  ensure
    @server.auto_refresh_on!
    ServerTasks.new.perform(:refresh_server, server.user.id, server_id)
  end
  
  def send_data_to_provisioner
    provision_tasks.create(server.id, role)
  end
  
  def wait_for_server_provisioned
    status = nil
    loop do
      status = job_status
      break if status.nil? || status[:status].in?(FINAL_STATUS)
      sleep POLLING_TIME
    end
    status
  end
 
  def job_status
    resp = provision_tasks.status(job_id)
    resp.status == 200 ? JSON.parse(resp.body).symbolize_keys : {status: "Error"}
  end
  
  def save_job_id
    server.update_attribute(:provisioner_job_id, job_id)
  end
  
  def set_provision_time
    server.update_attribute(:provisioned_at, Time.now)
  end
  
  def prov_error_params
    { source: 'DockerProvision', server_id: server.id,
      role: role, job_id: job_id,
      provisioner: provision_tasks.prov_server[:url]
    }
  end
  
  def provision_tasks
    @provision_tasks ||= DockerProvisionerTasks.new
  end
end
