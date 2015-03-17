class CreateTicket
  include Sidekiq::Worker

  def perform(ticket_id)
    ticket = Ticket.find(ticket_id)
    user = User.find(ticket.user.id)

    helpdesk = Helpdesk.new
    details = { subject: ticket.subject, body: ticket.body.html_safe, user: user, department: ticket.department }
    details[:server] = "#{ticket.server.name} (ID: #{ticket.server.id}, Location: #{ticket.server.location})" unless ticket.server.nil?

    id = helpdesk.new_ticket(ticket.id, details)
    ticket.update!(reference: id.to_s)
  end
end
