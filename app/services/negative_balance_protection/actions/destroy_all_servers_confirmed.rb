module NegativeBalanceProtection
  module Actions
    class DestroyAllServersConfirmed
      attr_reader :user, :manager, :destroy_performed
      
      def initialize(user)
        @user = user
        @manager = ServerTasks.new
        @destroy_performed = false
      end
      
      def perform
        return nil unless destroy_confirmed_by_admin?
        destroy_all_servers
        if destroy_performed
          create_activity
          log_risky_entities
        end
      end

      def destroy_confirmed_by_admin?
        user.server_destroy_scheduled?
      end
      
      def destroy_all_servers
        user.servers.each { |server| destroy(server) }
      end
      
      def destroy(server)
        manager.perform(:destroy, user.id, server.id)
        destroy_local_server(server)
      rescue Faraday::ClientError => e
        case
        when server_deleted_at_onapp?(e, server) then destroy_local_server(server)
        when server_suspended?(e, server) then admin_destroy(server)
        end
        log_error(e, server)
      rescue => e
        log_error(e, server)
      end
      
      def destroy_local_server(server)
        server.create_credit_note_for_time_remaining
        create_bandwidth_invoice(server)
        server.destroy_with_ip("balance checker: not paid invoices")
        @destroy_performed = true
      end
      
      def create_bandwidth_invoice(server)
        invoicer = DestroyServerTask.new(server, user, '')
        invoicer.create_destroy_invoice
        invoicer.charge_unpaid_invoices(user.account)
      end

      def admin_destroy(server)
        unsuspend_server(server)
        onapp_admin_destroy(server)
        destroy_local_server(server)
      rescue Faraday::ClientError => e
        log_error(e, server)
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

      def server_deleted_at_onapp?(e, server)
        return true if not_found?(e)
        onapp_vm(server) if unauthorized?(e)
        false
      rescue Faraday::ResourceNotFound
        true
      end
      
      def not_found?(e)
        e.response && e.response[:status] == 404
      end
      
      def unauthorized?(e)
        e.response && e.response[:status] == 401 
      end

      def onapp_suspended?(server)
        onapp_vm(server)["suspended"]
      end
      
      def onapp_vm(server)
        admin_squall.show(server.identifier)
      end
      
      def admin_squall
        @admin_squall = Squall::VirtualMachine.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
      end

      def create_activity
        user.create_activity(
          :destroy_all_servers, 
          owner: user
        )
      end
      
      def log_risky_entities
        user.account.log_risky_ip_addresses
        user.account.log_risky_cards
        create_sift_label
        label_devices
      end
      
      def create_sift_label
        label_properties = SiftProperties.sift_label_properties true, nil, "Balance checker: Unpaid invoices", "negative_balance_checker"
        SiftLabel.perform_async(:create, user.id.to_s, label_properties)
      end
      
      def label_devices
        LabelDevices.perform_async(user.id, "bad")
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
    end
  end
end
