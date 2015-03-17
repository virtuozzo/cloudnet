class TicketRepliesController < ApplicationController
  def create
    @ticket = Ticket.find(params[:ticket_id])

    @ticket_reply        = @ticket.ticket_replies.new(ticket_reply_params)
    @ticket_reply.sender = current_user.full_name
    @ticket_reply.user   = current_user
    @ticket_replies      = @ticket.ticket_replies(true)

    respond_to do |format|
      if @ticket_reply.save
        # Schedule the reply to be added to the Helpdesk
        AddTicketReply.perform_async(@ticket.reference, @ticket_reply.id)
        @ticket.create_activity :reply, owner: current_user, params: { ip: ip, admin: real_admin_id, reference: @ticket.reference }
        format.html { redirect_to @ticket, notice: 'Ticket reply has been added to ticket.' }
        format.json { render partial: 'tickets/ticket_reply.json', locals: { reply: @ticket_reply } }
      else
        format.html { redirect_to @ticket, error: 'Ticket reply could not be added to ticket.' }
        format.json { render json: { errors: @ticket_reply.errors }, status: :unprocessable_entity }
      end
    end
  end

  private

  def ticket_reply_params
    params.require(:ticket_reply).permit(:body)
  end
end
