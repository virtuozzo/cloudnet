module NegativeBalanceProtection
  module Actions
    class DestroyAllServersConfirmed
      attr_reader :user, :manager
      
      def initialize(user)
        @user = user
        @manager = ServerTasks.new
      end
      
      def perform
        return nil unless destroy_confirmed_by_admin?
        user.servers.each { |server| destroy(server) }
        create_activity
      end
      
      def destroy_confirmed_by_admin?
        user.server_destroy_scheduled?
      end
      
      def destroy(server)
        manager.perform(:destroy, user.id, server.id)
        destroy_local_server(server)
      rescue Faraday::ClientError => e
        admin_destroy(server) if server_suspended?(e, server)
        log_error(e, server)
      rescue => e
        log_error(e, server)
      end
      
      def destroy_local_server(server)
        server.create_credit_note_for_time_remaining
        server.destroy_with_ip("balance checker: not paid invoices")
        create_bandwidth_invoice(server)
      end
      
      def create_bandwidth_invoice(server)
        invoicer = DestroyServerTask.new(server, user, '')
        invoicer.create_destroy_invoice
        invoicer.charge_unpaid_invoices(user.account)
      end
      
      def create_activity
        user.create_activity(
          :destroy_all_servers, 
          owner: user
        )
      end
      
      def log_error(e, server)
        ErrorLogging.new.track_exception(
          e,
          extra: {
            user: user.id,
            server: server.id,
            source: 'ShutdownAllServers',
            faraday: e.response
          }
        )
      end
      
      def admin_destroy(server)
        unsuspend_server(server)
        onapp_admin_destroy(server)
        destroy_local_server(server)
        @shutdown_performed = true
      end
      
      def onapp_admin_destroy(server)
        admin_squall.delete(server.identifier)
      end
      
      def unsuspend_server(server)
        admin_squall.suspend(server.identifier)
      end
      
      def server_suspended?(e, server)
        unauthorized?(e) && onapp_suspended?(server)
      end
      
      def unauthorized?(e)
        e.response[:status] == 401 if e.response
      end
      
      def onapp_suspended?(server)
        admin_squall.show(server.identifier)["suspended"]
      end
        
      def admin_squall
        @admin_squall = Squall::VirtualMachine.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
      end
    end
  end
end