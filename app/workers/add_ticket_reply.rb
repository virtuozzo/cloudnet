class AddTicketReply
  include Sidekiq::Worker

  def perform(ticket_ref, reply_id)
    reply = TicketReply.find(reply_id)
    user = reply.ticket.user

    helpdesk = Helpdesk.new
    helpdesk.reply_ticket(ticket_ref, reply.body.html_safe, user)
  end
end
