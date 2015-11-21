module NegativeBalanceProtection
  module Actions
    class ShutdownAllServers
      attr_reader :user
      
      def initialize(user)
        @user = user
      end
      
      def perform
        user.servers.each { |server| shut_down(server) }
      end
      
      def shut_down(server)
        ServerTasks.new.perform(:shutdown, user.id, server.id)
      rescue => e
        log_error(e, server)
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