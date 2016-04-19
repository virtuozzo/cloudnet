class DockerProvisionerTasks
  attr_reader :server
  
  def create(server_id, role)
    @server = Server.find(server_id)
    connection.post '/job', provisioner_data(role)
  end

  def status(job_id)
    connection.get "/job/#{job_id}"
  end
  
  def roles
    connection.get "/roles"
  end

  def prov_server
    { 
      url: ENV['DOCKER_PROVISIONER'], 
      user: ENV['DOCKER_PROVISIONER_USER'],
      pass: ENV['DOCKER_PROVISIONER_PASS']
    }
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
      @connection ||= Faraday.new(:url => prov_server[:url]) do |builder|
        builder.request  :json
        builder.use Faraday::Response::Logger, Rails.logger
        builder.adapter Faraday.default_adapter
        builder.basic_auth prov_server[:user], prov_server[:pass]
      end
    end
end
