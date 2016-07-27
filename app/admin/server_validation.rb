ActiveAdmin.register Server, as: "ServerValidation" do
  actions :index
  menu label: "Server Validations"
  menu priority: 8
  
  scope("Existing", default: true) { |scope| scope.where(:deleted_at => nil) }
  scope "Deleted", :only_deleted
  scope "All", :with_deleted
  
  config.filters = false

  index :title => 'Server Validation List' do
    panel "Servers under validation" do 
      text_node "The following servers have been placed under validation due to possible fraud. When you approve a server, the respective account is marked as 'safe' and future servers created on the account are less likely to come under validation unless the account's fraud parameters change in the future.".html_safe
    end
    
    selectable_column
    column :id
    column :name do |server|
      link_to server.name, admin_server_path(server)
    end
    column :hostname
    column :state
    column :built
    column :cpus
    column :memory
    column :disk_size
    column "User", :unscoped_user
    column "Location", :unscoped_location
    column "Primary IP", :primary_ip_address do |server|
      (server.unscoped_server_ip_addresses.find(&:primary?) || server.unscoped_server_ip_addresses.first).address rescue nil
    end
    column "Validation Reason", :validation_reason_info do |server|
      Account::FraudValidator::VALIDATION_REASONS[server.validation_reason]
    end
    column :minfraud_score do |server|
      server.user.account.billing_cards.map{|card| card.fraud_score.round(2).to_f}.max rescue nil
    end
    column "Request IP", :request_ip do |server|
      server.activities.where(key: 'server.create').first.parameters[:ip] rescue nil
    end
    column :risky_cards do |server|
      server.user.account.risky_card_attempts rescue nil
    end
  end
  
  batch_action :approve, priority: 1 do |ids|
    ids.each do |id|
      begin
        # Reset validation reason, which means server is approved
        server = Server.find(id)
        server.update!(validation_reason: 0)
        create_activity(server, :approved)
      
        # Boot the server
        ServerTasks.new.perform(:startup, server.user_id, server.id)
        server.monitor_and_provision
        create_sift_event(server, "$approved")
        remove_sift_label(server)
        label_devices(server, "not_bad")
        create_activity(server, :startup)
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: server.user, source: 'ServerValidation#approve' })
        flash[:error] = "Could not start all servers"
      ensure
        # Reset fraud check parameters so future servers are not put in validation
        account = server.user.account
        if account
          account.billing_cards.map {|card| card.update!(fraud_safe: true)}
          account.risky_ip_addresses.map {|ip| ip.destroy }
          account.risky_cards.map {|card| card.destroy }
          account.update!(risky_cards_remaining: Account::RISKY_CARDS_ALLOWED)
        end
      end
    end
    redirect_to admin_server_validations_path
  end
  
  batch_action :destroy, priority: 2 do |ids|
    ids.each do |id|
      begin
        server = Server.find(id)
        destroy = DestroyServerTask.new(server, server.user, request.remote_ip)
        create_sift_event(server, "$canceled", "$payment_risk")
        create_sift_label(server)
        label_devices(server, "bad")
        create_activity(server, :destroy) if destroy.process && destroy.success?
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: server.user, source: 'ServerValidation#destroy' })
        flash[:error] = "Could not destroy all servers"
      end
    end
    redirect_to admin_server_validations_path
  end

  controller do
    def scoped_collection
      super.servers_under_validation
    end
    
    def create_activity(server, activity)
      server.create_activity(
        activity, 
        owner: server.user,
        params: { 
          ip: request.remote_ip,
          admin: current_user.id
        }
      )
    end
    
    def create_sift_event(server, order_status, reason = nil, description = nil)
      properties = {
        "$user_id"        => server.user_id,
        "$order_id"       => server.try(:last_generated_invoice_item).try(:invoice_id),
        "$source"         => "$manual_review",
        "$order_status"   => order_status,
        "$description"    => description,
        "$reason"         => reason,
        "$analyst"        => current_user.email
      }
      CreateSiftEvent.perform_async("$order_status", properties)
    rescue StandardError => e
      ErrorLogging.new.track_exception(e, extra: { user: server.user.id, source: 'ServerValidation#create_sift_event' })
    end
    
    def create_sift_label(server)
      reasons = case server.validation_reason
        when 2, 5; ["$duplicate_account"]
        when 4; ["$chargeback"]
      end
      description = Account::FraudValidator::VALIDATION_REASONS[server.validation_reason]
      label_properties = SiftProperties.sift_label_properties true, reasons, description, "manual_review", current_user.email
      SiftLabel.perform_async(:create, server.user_id.to_s, label_properties)
    end
    
    def remove_sift_label(server)
      SiftLabel.perform_async(:remove, server.user_id.to_s)
    end
    
    def label_devices(server, label)
      LabelDevices.perform_async(server.user_id, label)
    end
  end
  
end
