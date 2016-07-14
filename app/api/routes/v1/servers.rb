module Routes::V1
  # /servers
  class Servers < Grape::API
    class CreateError < StandardError; end
    
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
        detail '<br><strong>WARNING:</strong> If successful that <strong>REALLY CREATES</strong> a server on your account, for which you will be charged.'
        failure [[400, 'Bad Request'], [401, 'Unauthorized']]
      end
      
      params do
        requires :template_id, type: Integer, desc: "Template IDs available from 'GET /datacentres/:id'"
        optional :name, type: String, desc: 'Human-readable name for server', documentation: { example: 'Jim' }
        optional :hostname, type: String, desc: 'OS-compatible hostname'
        optional :memory, type: Integer, default: 1024, desc: 'Amount of memory in MBs, default 1024 MB'
        optional :disk_size, type: Integer, default: 20, desc: 'Size of primary disk in GBs, default 20 GB'
        optional :cpus, type: Integer, default: 1, desc: 'Number of cpus, default 1'
      end
      post do
        requested_params = declared(params, include_missing: false).deep_symbolize_keys
        actions = CreateServerSupportActions.new(current_user)
        server_check = actions.server_check(requested_params, request.ip)
        
        begin
          raise CreateError unless server_check.valid?
          create_task = CreateServerTask.new(server_check, current_user)
          raise CreateError unless create_task.process
          present create_task.server,  with: ServerRepresenter
          
        rescue CreateError
          error! actions.build_api_errors, 500
        end
      end

      params do
        requires :id, type: Integer, desc: 'Server ID'
      end
      route_param :id do
        desc 'Destroy a server' do
          detail '<br><strong>WARNING:</strong> If successful that <strong>REALLY DESTROYS</strong> a server on your account.'
          failure [
            {code: 200, message: 'ok'},
            {code: 400, message: 'Bad Request'},
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
          failure [[400, 'Bad Request'], [401, 'Unauthorized'], [404, 'Not Found']]
        end
        get do
          present current_user.servers.find(params[:id]),  with: ServerRepresenter
        end
      end
    end
  end
end
