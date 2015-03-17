require 'rails_helper'

describe AddTicketReply do
  let!(:ticket) { FactoryGirl.create(:ticket) }
  let(:ticket_reply) { FactoryGirl.create(:ticket_reply, ticket: ticket) }

  it 'should attempt to add the reply to helpdesk' do
    helpdesk = double('Helpdesk', reply_ticket: true)
    allow(Helpdesk).to receive(:new).and_return(helpdesk)

    AddTicketReply.new.perform(ticket.reference, ticket_reply.id)
    expect(helpdesk).to have_received(:reply_ticket)
  end
end
