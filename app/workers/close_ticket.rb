class CloseTicket
  include Sidekiq::Worker

  def perform(ticket_ref)
    helpdesk = Helpdesk.new
    helpdesk.close_ticket(ticket_ref)
  end
end
