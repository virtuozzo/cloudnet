module NegativeBalanceProtection
  module Actions
    class DestroyAllServersConfirmed
      attr_reader :user
      
      def initialize(user)
        @user = user
      end
      
      def perform
        return nil unless destroy_confirmed_by_admin?
        user.servers.each { |server| destroy(server) }
      end
      
      def destroy_confirmed_by_admin?
        user.server_destroy_scheduled?
      end
      
      def destroy(server)
        ServerTasks.new.perform(:destroy, user.id, server.id)
        server.create_credit_note_for_time_remaining if server.prepaid?
        server.destroy_with_ip("not paid invoices")
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