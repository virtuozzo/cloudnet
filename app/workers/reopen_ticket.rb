class ReopenTicket
  include Sidekiq::Worker

  def perform(ticket_ref)
    helpdesk = Helpdesk.new
    helpdesk.reopen_ticket(ticket_ref)
  end
end
