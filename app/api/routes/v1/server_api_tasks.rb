module Routes::V1
  # /servers
  class ServerApiTasks< Grape::API
    version :v1, using: :accept_version_header
    resource :servers do

      before do
        authenticate!

      end

      params do
        requires :id, type: Integer, desc: 'Server ID'
      end

      route_param :id do
        before do
          @server = current_user.servers.find(params[:id])
          @actions = ServerSupportActions.new(current_user)
        end
        desc 'Reboot a server' do
          failure [
            {code: 200, message: 'Schedule server reboot'},
            {code: 400, message: 'Bad Request'},
            {code: 401, message: 'Unauthorized'},
            {code: 404, message: 'Not Found'} ]
        end

        put 'reboot' do
          @actions.schedule_task(:reboot, @server.id)
          log_activity :reboot, @server
          create_sift_event :reboot_server, @server.sift_server_properties
          present @server, with: ServerRepresenter
        end

        desc 'Shut down a server' do
          failure [
            {code: 200, message: 'Schedule server shutdown'},
            {code: 400, message: 'Bad Request'},
            {code: 401, message: 'Unauthorized'},
            {code: 404, message: 'Not Found'} ]
        end

        put 'shutdown' do
          @actions.schedule_task(:shutdown, @server.id)
          log_activity :shutdown, @server
          create_sift_event :shutdown_server, @server.sift_server_properties
          present @server, with: ServerRepresenter
        end

        desc 'Start up a server' do
          failure [
            {code: 200, message: 'Schedule server startup'},
            {code: 400, message: 'Bad Request'},
            {code: 401, message: 'Unauthorized'},
            {code: 404, message: 'Not Found'} ]
        end

        put 'startup' do
          @actions.schedule_task(:startup, @server.id)
          log_activity :startup, @server
          create_sift_event :startup_server, @server.sift_server_properties
          present @server, with: ServerRepresenter
        end
      end
    end
  end
end