class DockerProvisionerTasks
  attr_reader :server
  
  def create(server_id, role)
    @server = Server.find(server_id)
    connection.post '/job', provisioner_data(role)
  end

  def status(job_id)
    connection.get "/job/#{job_id}"
  end

  private
  
    def provisioner_data(role)
      {
        role: role || "ping",
        ip: ip_address,
        password: server.root_password,
        username: "root"
      }
    end
  
    def ip_address
      server.server_ip_addresses.first.address
    end
  
    def connection
      @connection ||= Faraday.new(:url => docker_url) do |builder|
        builder.request  :json
        builder.use Faraday::Response::Logger, Rails.logger
        builder.adapter Faraday.default_adapter
      end
    end
  
    def docker_url
      "http://#{prov_ip_address}/"
    end
  
    def prov_ip_address
      ENV['DOCKER_PROVISIONER']
    end
end
