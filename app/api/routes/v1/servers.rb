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
        requires :template_id, type: Integer, desc: "Template IDs available from 'GET /datacentres/:id'"
        optional :name, type: String, desc: 'Human-readable name for server'
        optional :hostname, type: String, desc: 'OS-compatible hostname'
        optional :memory, type: Integer, default: 1024, desc: 'Amount of memory in MBs, default 1024 MB'
        optional :disk_size, type: Integer, default: 20, desc: 'Size of primary disk in GBs, default 20 GB'
        optional :cpus, type: Integer, default: 1, desc: 'Number of cpus, default 1'
      end
      post do
        requested_params = declared(params, include_missing: false).deep_symbolize_keys
        location_id = Template.find(requested_params[:template_id]).location.id
        validation_reason = current_user.account.fraud_validation_reason(request.ip)
        server_params = { location_id: location_id, name: 'def', hostname: 'def', 
                          provisioner_role: nil,
                          ip_addresses: 1, validation_reason: validation_reason, user: current_user
                        }.merge(requested_params)
            
        server_check = ServerWizard.new(server_params)
        if server_check.valid?
          create_task = CreateServerTask.new(server_check, current_user)
          if create_task.process
            present create_task.server,  with: ServerRepresenter
          else
            error! 'not good'
          end
        else
          error! server_check.errors.messages.values.join(', '), 500
        end
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
          present current_user.servers.find(params[:id]),  with: ServerRepresenter
        end
      end
    end
  end
end
