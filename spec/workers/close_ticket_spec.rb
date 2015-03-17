require 'rails_helper'

describe CloseTicket do
  let(:ticket) { FactoryGirl.create(:ticket) }

  it 'should attempt to close a ticket' do
    helpdesk = double('Helpdesk')
    allow(Helpdesk).to receive(:new).and_return(helpdesk)
    allow(helpdesk).to receive(:close_ticket).and_return(true)

    ticket.reference = '1234567abc'
    CloseTicket.new.perform(ticket.reference)
    expect(helpdesk).to have_received(:close_ticket).with(ticket.reference)
  end
end
