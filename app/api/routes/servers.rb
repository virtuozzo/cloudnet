module Routes
  # /servers
  class Servers < Grape::API
    version :v1, using: :accept_version_header
    resource :servers do
      
      before do
        authenticate!
      end

      desc 'List all servers'
      get do
        present current_user.servers.to_a, with: ServersRepresenter
      end

      desc 'Create a server'
      params do
        requires :template, type: Integer, desc: "Template IDs available from 'GET /datacentres/:id'"
        optional :name, type: String, desc: 'Human-readable name for server'
        optional :hostname, type: String, desc: 'OS-compatible hostname'
        optional :memory, type: Integer, desc: 'Amount of memory in MBs'
        optional :disk_size, type: Integer, desc: 'Size of primary disk in GBs'
      end
      post do

      end

      params do
        requires :id, type: String, desc: 'Server ID'
      end
      route_param :id do
        desc 'Destroy a server'
        delete do
          { message: "Server #{params[:id]} has been scheduled for destruction" }
        end

        desc 'Show information about a server'
        get do
          present Server.find(params[:id]), with: ServerRepresenter
        end
      end
    end
  end
end
