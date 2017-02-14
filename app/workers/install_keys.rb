class InstallKeys
  include Sidekiq::Worker
  sidekiq_options :retry => 5
  attr_reader :server, :job_id, :keys
  
  FINAL_STATUS = %w(Failed Done Error Aborted)
  POLLING_TIME = 30.seconds
  
  class ProvisionerError < StandardError; end
    
  def perform(server_id, key_ids)
    @server = Server.find(server_id)
    @job_id = nil
    
    if server_booted? && server_has_ip? && no_pending_events?
      @keys = formatted_keys(key_ids)
      resp = send_keys_to_provisioner
    else
      InstallKeys.perform_in(POLLING_TIME, server_id, key_ids)
      return
    end
    
    case resp.status
    when 200..209
      @job_id = resp.body
      status = wait_for_server_provisioned[:status]
      if status == "Done"
        server.create_activity :added_ssh_key, owner: server.user, params: { keys: key_ids }
      else
        raise(ProvisionerError, status)
      end
    else
      server.create_activity :failed_ssh_key, owner: server.user, params: { keys: key_ids, status: status }
      raise(ProvisionerError, resp.status)
    end
    
  rescue => e
    Rails.logger.warn "Provisioning of SSH Keys for server #{server_id} failed"
    ErrorLogging.new.track_exception(e, extra: prov_error_params)
  end
  
  private
  
  def formatted_keys(key_ids)
    { 'ssh-keys' => server.user.keys.where(id: key_ids).map(&:key) }
  end
  
  def server_booted?
    server.state.in?([:on, :provisioning])
  end
  
  def server_has_ip?
    server.server_ip_addresses.first.try(:address)
  end
  
  def no_pending_events?
    server.server_events.where.not(status: :complete).size == 0
  end
  
  def send_keys_to_provisioner
    provision_tasks.create(server.id, "ssh-keys", keys)
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
  
  def prov_error_params
    { source: 'InstallKeys', server_id: server.id,
      job_id: job_id,
      provisioner: provision_tasks.prov_server[:url]
    }
  end
  
  def provision_tasks
    @provision_tasks ||= DockerProvisionerTasks.new
  end
end
