class SupportTasks < BaseTasks
  
  def perform(action, user, servers = nil)
    @user = user
    run_task(action, servers)
  end
  
  private
  
  def notify_server_validation(servers)
    subject = "Server(s) under validation"
    body = "Please validate my servers."
    server_id = servers.size > 1 ? nil : servers.first.id
    create_ticket(subject, body, "billing", server_id)
  end
  
  def create_ticket(subject, body, department, server_id = nil)
    ticket = Ticket.new(subject: subject, body: body, department: department, user: @user, server_id: server_id)
    ticket.save
    CreateTicket.new.perform(ticket.id)
  end
  
  def allowable_methods
    super + [:notify_server_validation]
  end
  
end
