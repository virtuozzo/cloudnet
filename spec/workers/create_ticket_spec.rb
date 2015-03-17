require 'rails_helper'

describe CreateTicket do
  let(:ticket) { FactoryGirl.create(:ticket) }

  it 'should attempt to create a ticket' do
    helpdesk = double('Helpdesk', new_ticket: true)
    allow(Helpdesk).to receive(:new).and_return(helpdesk)

    CreateTicket.new.perform(ticket.id)
    expect(helpdesk).to have_received(:new_ticket)
  end
end
