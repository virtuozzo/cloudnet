class TicketsController < ApplicationController
  before_action :set_ticket, only: [:show, :edit, :close, :reopen]

  skip_filter :authenticate_user!, only: [:ticket_response, :ticket_created]
  skip_filter :check_user_status, only: [:ticket_response, :ticket_created]
  skip_filter :verify_authenticity_token, only: [:ticket_response, :ticket_created]
  before_filter :basic_auth, only: [:ticket_response, :ticket_created]

  def index
    @tickets = current_user.tickets.order(updated_at: :desc)

    respond_to do |format|
      format.html { @tickets = @tickets.page(params[:page]).per(10) }
      format.json { render json: @tickets }
    end
  end

  def show
    @ticket_replies = @ticket.ticket_replies(true).order(created_at: :asc)
    respond_to do |format|
      format.json
      format.html
    end
  end

  def new
    @servers = current_user.servers
    @ticket = Ticket.new
  end

  def create
    @servers = current_user.servers
    @ticket = Ticket.new ticket_params.merge(user: current_user)

    respond_to do |format|
      if @ticket.save
        # Schedule the creation of the ticket in the helpdesk
        # TODO: Make this back into a background task again
        CreateTicket.new.perform(@ticket.id)
        log_activity :create

        format.html { redirect_to @ticket, notice: 'Ticket was successfully created.' }
        format.json { render action: 'show', status: :created, location: @ticket }
      else
        format.html { render action: 'new' }
        format.json { render json: @ticket.errors, status: :unprocessable_entity }
      end
    end

    Analytics.track(
      current_user,
      event: 'Created a ticket',
      properties: {
        subject: @ticket.subject
      }
    )
  end

  def reopen
    respond_to do |format|
      if @ticket.status != :solved
        format.html { redirect_to @ticket, notice: 'Ticket has not been solved.' }
      else
        ReopenTicket.perform_async(@ticket.reference)
        @ticket.update(status: :open)
        log_activity :reopen
        format.html { redirect_to @ticket, notice: 'Ticket has been reopened.' }
      end
    end

    Analytics.track(
      current_user,
      event: 'Reopened a ticket',
      properties: {
        subject: @ticket.subject
      }
    )
  end

  def close
    respond_to do |format|
      if @ticket.completed?
        format.html { redirect_to @ticket, notice: 'Ticket has already been closed.' }
      else
        CloseTicket.perform_async(@ticket.reference)
        @ticket.update(status: :closed)
        log_activity :close
        format.html { redirect_to @ticket, notice: 'Ticket has been closed.' }
      end
    end

    Analytics.track(
      current_user,
      event: 'Closed a ticket',
      properties: {
        subject: @ticket.subject
      }
    )
  end

  def ticket_created
    ticket_ref = params[:ref].to_s
    CreateTicketFromRemote.perform_async(ticket_ref)
    render nothing: true, status: 204
  end

  def ticket_response
    ticket_ref = params[:ref].to_s
    ProcessTicketResponse.perform_async(ticket_ref)
    render nothing: true, status: 204
  end

  private

  def set_ticket
    @ticket = current_user.tickets.find(params[:id])
  end

  def ticket_params
    params.require(:ticket).permit(:subject, :body, :department, :server_id)
  end

  def basic_auth
    config = Helpdesk.config

    authenticate_or_request_with_http_basic do |username, password|
      username == config[:trigger_auth][:user] && password == config[:trigger_auth][:pass]
    end
  end

  def log_activity(activity)
    @ticket.create_activity activity, owner: current_user, params: { ip: ip, admin: real_admin_id, reference: @ticket.reference }
  end
end
