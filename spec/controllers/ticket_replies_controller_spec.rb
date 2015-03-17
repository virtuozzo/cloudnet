require 'rails_helper'

describe TicketRepliesController do
  let (:reply) { FactoryGirl.create(:ticket_reply) }

  describe 'as a user not signed in' do
    it 'should redirect me to the sign in page' do
      post :create, ticket_id: reply.ticket.id
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'as a signed in user' do
    before(:each) { sign_in_onapp_user }

    describe 'creating a ticket reply' do
      before(:each) do
        AddTicketReply.jobs.clear
      end

      it 'should go to show page if ticket reply is fine' do
        assert_equal 0, AddTicketReply.jobs.size
        post :create, ticket_reply: reply.attributes, ticket_id: reply.ticket.id
        expect(assigns(:ticket_reply)).to be_valid
        expect(response).to redirect_to(ticket_path(reply.ticket))
        assert_equal 1, AddTicketReply.jobs.size
      end

      it "should render failure if ticket isn't valid" do
        reply.body = ''
        post :create, ticket_id: reply.ticket.id, ticket_reply: reply.attributes
        expect(assigns(:ticket_reply)).to_not be_valid
        assert_equal 0, AddTicketReply.jobs.size
      end

      it 'should render failure if the ticket is already completed' do
        reply.ticket.update(status: :solved)
        post :create, ticket_id: reply.ticket.id, ticket_reply: reply.attributes
        expect(assigns(:ticket_reply)).to_not be_valid
        assert_equal 0, AddTicketReply.jobs.size
      end
    end
  end

end
