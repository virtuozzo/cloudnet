require 'rails_helper'

describe ReopenTicket do
  let(:ticket) { FactoryGirl.create(:ticket) }

  it 'should attempt to reopen the ticket' do
    helpdesk = double('Helpdesk', reopen_ticket: true)
    allow(Helpdesk).to receive(:new).and_return(helpdesk)

    ReopenTicket.new.perform(ticket.id)
    expect(helpdesk).to have_received(:reopen_ticket)
  end
end
