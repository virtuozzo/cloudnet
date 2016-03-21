class SupportTasks < BaseTasks
  
  def perform(action, user, server = nil)
    @user = user
    run_task(action, server)
  end
  
  private
  
  def notify_server_validation(server)
    subject = "Server is under validation - #{server.hostname}"
    body = "Please validate my server."
    create_ticket(subject, body, "billing", server.id)
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
