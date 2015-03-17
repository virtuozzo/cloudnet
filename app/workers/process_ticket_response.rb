class ProcessTicketResponse
  include Sidekiq::Worker

  def perform(reference)
    return if reference.nil? || reference.blank?
    ticket = Ticket.find_by_reference(reference)
    return if ticket.nil?

    begin
      helpdesk = Helpdesk.new
      details = helpdesk.ticket_details(reference)

      ticket.process_status(details[:status])
      details[:replies].each do |reply|
        ticket.process_reply(reply)
      end
    rescue Exception => e
      ErrorLogging.new.track_exception(e, extra: { source: 'ProcessTicketResponse', ref: reference })
    end
  end
end
