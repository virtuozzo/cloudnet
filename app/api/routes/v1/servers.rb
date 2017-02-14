module Routes::V1
  # /servers
  class Servers < Grape::API
    class CreateError < StandardError; end
    include Grape::Kaminari

    version :v1, using: :accept_version_header
    resource :servers do

      before do
        authenticate!
      end

      desc 'List all servers' do
        detail "<br>Answer is paginated.<br>Please verify: X-Total, X-Total-Pages, X-Per-Page, X-Page, X-Next-Page (if exists), X-Prev-Page (if exists) headers"
        failure [[400, 'Bad Request'], [401, 'Unauthorized']]
      end
      paginate per_page: 10, max_per_page: 20, offset: false
      get do
        present paginate(current_user.servers), with: ServersRepresenter
      end

      desc 'Create a server' do
        detail '<br><strong>WARNING:</strong> If successful that <strong>REALLY CREATES</strong> a server on your account, for which you will be charged.'
        failure [[400, 'Bad Request'], [401, 'Unauthorized']]
      end

      params do
        requires :template_id, type: Integer, desc: "Template IDs available from 'GET /datacentres/:id'"
        optional :name, type: String, desc: 'Human-readable name for server', documentation: { example: 'Jim' }
        optional :hostname, type: String, desc: 'OS-compatible hostname'
        optional :memory, type: Integer, default: 1024, desc: 'Amount of memory in MBs, default 1024 MB, max 8192 MB', values: 128..8192
        optional :disk_size, type: Integer, default: 20, desc: 'Size of primary disk in GBs, default 20 GB, max 120 GB', values: 5..120
        optional :cpus, type: Integer, default: 1, desc: 'Number of cpus, default 1, max 6', values: 1..6
      end
      post do
        requested_params = declared(params, include_missing: false).deep_symbolize_keys
        actions = ServerSupportActions.new(current_user)
        server_check = actions.server_check(requested_params, request.ip)
        begin
          raise CreateError unless server_check.valid?
          create_task = CreateServerTask.new(server_check, current_user)
          raise CreateError unless create_task.process

          server = create_task.server
          log_activity :create, server, provisioned: server.provisioner_role

          Analytics.track(
            current_user,
            event: "API New Server Created",
            properties: {
              location: server.location.to_s,
              template: server.template.to_s,
              server: "#{server.memory}MB RAM, #{server.disk_size}GB Disk, #{server.cpus} Cores",
              provisioned: server.provisioner_role
            }
          )
          present server,  with: ServerRepresenter

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
            log_activity :destroy, server
            Analytics.track(
              current_user,
              event: 'API Destroyed Server',
              properties: {
                server: server.to_s,
                specs: "#{server.memory}MB RAM, #{server.disk_size}GB Disk, #{server.cpus} Cores"
              }
            )
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

        desc 'Edit a server' do
          failure [
            {code: 200, message: 'Schedule server change'},
            {code: 400, message: 'Bad Request'},
            {code: 401, message: 'Unauthorized'},
            {code: 404, message: 'Not Found'} ]
        end
        params do
          optional :memory, type: Integer, desc: 'Amount of memory in MBs (128..8192)', values: 128..8192
          optional :cpus, type: Integer, desc: 'Number of cpus (1..6)', values: 1..6
          optional :disk_size, type: Integer, desc: 'Size of primary disk in GBs, min 6 GB,  max 120 GB', values: 6..120
          optional :template_id, type: Integer, desc: "Template IDs available from 'GET /datacentres/:id'"
        end
        put do
          server = current_user.servers.find(params[:id])
          old_server_specs = Server.new server.as_json
          requested_params = declared(params, include_missing: false).deep_symbolize_keys
          actions = ServerSupportActions.new(current_user)
          edit_wizard = actions.prepare_edit(server, requested_params)
          edit_wizard.set_old_server_specs(old_server_specs)
          begin
            raise CreateError if server.no_refresh
            raise CreateError unless edit_wizard.valid?
            actions.update_edited_server(server, requested_params, edit_wizard)
            result = actions.schedule_edit(edit_wizard, old_server_specs)
            raise CreateError if result.build_errors.length > 0
            log_activity :edit, server,
              {
                old_disk_size: old_server_specs.disk_size,
                old_memory: old_server_specs.memory,
                old_cpus: old_server_specs.cpus,
                old_name: old_server_specs.name,
                old_distro: old_server_specs.template.name,
                new_disk_size: server.disk_size,
                new_memory: server.memory,
                new_cpus: server.cpus,
                new_name: server.name,
                new_distro: server.template.name
              }
            present server, with: ServerRepresenter
          rescue CreateError
            error = {}
            error.merge!(edit: "Server edit in progress. Wait until status is 'on'") if server.no_refresh
            error.merge! build: result.build_errors if result && result.build_errors.any?
            error.merge! edit_wizard.errors.messages.each_with_object({}) { |e, m| m[e[0]] = e[1] }
            msg = { "error" => error }
            error! msg, 500
          end
        end
      end
    end
  end
end
