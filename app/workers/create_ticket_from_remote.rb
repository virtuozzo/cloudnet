class CreateTicketFromRemote
  include Sidekiq::Worker

  def perform(ticket_ref)
    return unless Ticket.find_by(reference: ticket_ref).nil?

    helpdesk = Helpdesk.new
    ticket_details = helpdesk.get_ticket(ticket_ref)
    user = User.find_by_email(ticket_details[:author_email])
    return if user.nil?

    ticket = Ticket.create(
      reference: ticket_details[:id].to_s,
      subject: ticket_details[:subject],
      body: ticket_details[:body],
      user: user,
      created_at: ticket_details[:created_at]
    )

    ticket.process_status(ticket_details[:status])
  end
end
