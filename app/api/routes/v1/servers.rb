module Routes::V1
  # /servers
  class Servers < Grape::API
    version :v1, using: :accept_version_header
    resource :servers do
      
      before do
        authenticate!
      end

      desc 'List all servers' do
        failure [[401, 'Unauthorized']]
      end
      get do
        present current_user.servers.to_a, with: ServersRepresenter
      end

      desc 'Create a server' do
        failure [[401, 'Unauthorized']]
      end
      
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
        requires :id, type: Integer, desc: 'Server ID'
      end
      route_param :id do
        desc 'Destroy a server' do
          failure [
            {code: 200, message: 'ok'},
            {code: 401, message: 'Unauthorized'}, 
            {code: 404, message: 'Not Found'} ]
        end

        delete do
          server = current_user.servers.find(params[:id])
          destroy = DestroyServerTask.new(server, current_user, request.ip)
          if destroy.process && destroy.success?
            body false
            #{ message: "Server #{params[:id]} has been scheduled for destruction" }
          else
            error! destroy.errors.join(', '), 500
          end
        end

        desc 'Show information about a server' do
          failure [[401, 'Unauthorized'], [404, 'Not Found']]
        end
        get do
          present current_user.servers.find(params[:id])
        end
      end
    end
  end
end
