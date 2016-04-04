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
      "The following servers have been placed under validation due to possible fraud."
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
      server.user.account.primary_billing_card.fraud_score.round(2)
    end
    column "Request IP", :request_ip do |server|
      server.activities.where(key: 'server.create').first.parameters[:ip] rescue nil
    end
    column :risky_cards do |server|
      server.user.account.risky_card_attempts
    end
  end
  
  batch_action :approve, priority: 1 do |ids|
    ids.each do |id|
      # Reset validation reason, which means server is approved
      server = Server.find(id)
      server.update!(validation_reason: 0)
      create_activity(server, :approved)
      
      # Boot the server
      ServerTasks.new.perform(:startup, server.user_id, server.id)
      MonitorServer.perform_in(MonitorServer::POLL_INTERVAL.seconds, server.id, server.user_id)
      create_activity(server, :startup)
      
      # Reset fraud check parameters so future servers are not put in validation
      server.user.account.primary_billing_card.update!(fraud_safe: true)
      server.user.account.risky_ip_addresses.map {|ip| ip.destroy }
      server.user.account.update!(risky_cards_remaining: Account::RISKY_CARDS_ALLOWED)
    end
    redirect_to admin_server_validations_path
  end
  
  batch_action :destroy, priority: 2 do |ids|
    ids.each do |id|
      server = Server.find(id)      
      destroy = DestroyServerTask.new(server, server.user, request.remote_ip)
      create_activity(server, :destroy) if destroy.process && destroy.success?
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
  end
  

end
