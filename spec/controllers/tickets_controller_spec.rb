require 'rails_helper'

describe TicketsController do
  describe 'as a user not signed in' do
    it 'should redirect me to the sign in page' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'as a signed in user' do
    before(:each) { sign_in_onapp_user }

    describe 'going to the index page' do
      it 'should be on the tickets index page' do
        get :index
        expect(response).to be_success
        expect(response).to render_template('tickets/index')
      end

      it 'should assign @tickets to display for the current user' do
        tickets = FactoryGirl.create_list(:ticket, 5, user: @current_user)
        get :index
        expect(assigns(:tickets)).to match_array(tickets)
      end
    end

    describe 'going to the ticket create page' do
      it 'should be on the new page' do
        get :new
        expect(response).to be_success
        expect(response).to render_template('tickets/new')
      end

      it 'should create a new ticket model' do
        get :new
        expect(assigns[:ticket]).to be_a(Ticket)
      end
    end

    describe 'going to the ticket show page' do
      let(:ticket) { FactoryGirl.create(:ticket, user: @current_user) }

      it 'should render the show template' do
        get :show, id: ticket.id
        expect(response).to render_template('tickets/show')
      end

      it 'should show information about the ticket' do
        get :show, id: ticket.id
        expect(assigns(:ticket)).to eq(ticket)
      end
    end

    describe 'creating a ticket' do
      before(:each) do
        CreateTicket.jobs.clear
      end

      let (:ticket) { FactoryGirl.create(:ticket) }

      it 'should go to show page if ticket is fine' do
        helpdesk = double('Helpdesk')
        allow(Helpdesk).to receive(:new).and_return(helpdesk)
        allow(helpdesk).to receive(:new_ticket).and_return(true)
        post :create, ticket: ticket.attributes
        expect(assigns(:ticket)).to be_valid
      end

      it "should render failure if ticket isn't valid" do
        ticket.body = ''
        post :create, ticket: ticket.attributes
        expect(assigns(:ticket)).to_not be_valid
        expect(assigns(:ticket).reference).not_to eq(25)
      end
    end

    describe 'closing a ticket' do
      before(:each) do
        CloseTicket.jobs.clear
      end

      let(:ticket) { FactoryGirl.create(:ticket, user: @current_user) }

      it 'should close a ticket' do
        assert_equal 0, CloseTicket.jobs.size
        post :close, id: ticket.id
        expect(assigns(:ticket).status).to eq(:closed)
        expect(response).to redirect_to(ticket_path(ticket.id))
        assert_equal 1, CloseTicket.jobs.size
      end

      it "should not close a ticket again if it's already closed or solved" do
        ticket.update!(status: :solved)
        expect(ticket.completed?).to be true

        post :close, id: ticket.id
        expect(assigns(:ticket).status).to eq(:solved)
        expect(assigns(:ticket).status).not_to eq(:closed)
      end
    end

    describe 'ticket response pushing' do
      before(:each) do
        ProcessTicketResponse.jobs.clear
      end

      it 'should request HTTP basic credentials for the page' do
        get :ticket_response, ref: 'abc123'
        assert_equal 401, response.response_code
      end

      it 'should return a 204 success if the correct HTTP auth is provided' do
        assert_equal 0, ProcessTicketResponse.jobs.size
        config = Helpdesk.config
        http_basic_auth config[:trigger_auth][:user], config[:trigger_auth][:pass]
        get :ticket_response, ref: 'abc123'
        assert_equal 204, response.response_code
        assert_equal 1, ProcessTicketResponse.jobs.size
      end

      it 'should return a 401 if the wrong auth is provided' do
        http_basic_auth 'invalid', 'invalid'
        get :ticket_response, ref: 'abc123'
        assert_equal 401, response.response_code
      end
    end

    describe 'ticket create pushing' do
      before(:each) do
        CreateTicketFromRemote.jobs.clear
      end

      it 'should request HTTP basic credentials for the page' do
        get :ticket_created, ref: 'abc123'
        assert_equal 401, response.response_code
      end

      it 'should return a 204 success if the correct HTTP auth is provided' do
        assert_equal 0, CreateTicketFromRemote.jobs.size
        config = Helpdesk.config
        http_basic_auth config[:trigger_auth][:user], config[:trigger_auth][:pass]
        get :ticket_created, ref: 'abc123'
        assert_equal 204, response.response_code
        assert_equal 1, CreateTicketFromRemote.jobs.size
      end

      it 'should return a 401 if the wrong auth is provided' do
        http_basic_auth 'invalid', 'invalid'
        get :ticket_created, ref: 'abc123'
        assert_equal 401, response.response_code
      end
    end

    describe 'ticket reopening' do
      before(:each) do
        ReopenTicket.jobs.clear
      end

      let (:ticket) { FactoryGirl.create(:ticket, user: @current_user) }

      it 'should allow reopening only if ticket is solved' do
        ticket.update(status: :solved)
        assert_equal 0, ReopenTicket.jobs.size
        post :reopen, id: ticket.id
        expect(assigns(:ticket).status).to eq(:open)
        expect(response).to redirect_to(ticket_path(ticket.id))
        assert_equal 1, ReopenTicket.jobs.size
      end

      it 'should not allow reopening if ticket is not solved' do
        ticket.update(status: :pending)
        assert_equal 0, ReopenTicket.jobs.size
        post :reopen, id: ticket.id
        expect(assigns(:ticket).status).to eq(:pending)
        expect(response).to redirect_to(ticket_path(ticket.id))
        assert_equal 0, ReopenTicket.jobs.size
      end
    end
  end
end
