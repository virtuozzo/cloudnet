class SupportTasks < BaseTasks
  
  def perform(action, user, servers = nil)
    @user = user
    run_task(action, servers)
  end
  
  private
  
  def notify_addons_request(servers)
    server = servers.first
    subject = "Add-on request - #{server.hostname}"
    server.server_addons.with_deleted.where(notified_at: nil).each do |server_addon|
      next unless server_addon.addon.request_support
      status = server_addon.deleted? ? "de-activate" : "activate"
      body = "Please #{status} '#{server_addon.addon.name}' for Server ID: #{server.id} (#{server.hostname})"
      create_ticket(subject, body, "billing", server.id)
      server_addon.update_attribute :notified_at, Time.now
    end
  end
  
  def notify_server_validation(servers)
    subject = "Server(s) under validation"
    body = "Please validate my servers."
    server_id = servers.size > 1 ? nil : servers.first.id
    create_ticket(subject, body, "billing", server_id)
  end
  
  def create_ticket(subject, body, department, server_id = nil)
    ticket = Ticket.new(subject: subject, body: body, department: department, user: @user, server_id: server_id)
    ticket.save
    CreateTicket.perform_async(ticket.id)
  end
  
  def allowable_methods
    super + [:notify_server_validation, :notify_addons_request]
  end
  
end
