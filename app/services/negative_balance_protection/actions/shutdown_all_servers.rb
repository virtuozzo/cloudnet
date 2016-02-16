module NegativeBalanceProtection
  module Actions
    class ShutdownAllServers
      attr_reader :user, :manager, :shutdown_performed
      
      def initialize(user)
        @user = user
        @shutdown_performed = false
        @manager = ServerTasks.new
      end
      
      def perform
        user.servers.each { |server| shut_down(server) if server_booted?(server) }
        create_activity if shutdown_performed
      end
      
      def shut_down(server)
        manager.perform(:shutdown, user.id, server.id)
        @shutdown_performed = true
      rescue => e
        log_error(e, server)
      end
      
      def server_booted?(server)
        manager.perform(:show, user.id, server.id)['booted']
      rescue => e
        log_error(e, server)
        true
      end
      
      private
      
      def create_activity
        user.create_activity(
          :shutdown_all_servers, 
          owner: user
        )
      end
      
      def log_error(e, server)
        ErrorLogging.new.track_exception(
          e,
          extra: {
            user: user,
            server: server,
            source: 'ShutdownAllServers',
            faraday: e.response
          }
        )
      end
      
    end
  end
end