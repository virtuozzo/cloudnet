require 'rails_helper'

describe ProcessTicketResponse do
  let(:ticket) { FactoryGirl.create(:ticket, reference: 'VALIDREF') }

  it "shouldn't process a response if the reference isn't valid" do
    helpdesk = double('Helpdesk', ticket_details: { status: :pending, replies: [] })
    allow(Helpdesk).to receive(:new).and_return(helpdesk)

    ProcessTicketResponse.new.perform('INVALIDREF')
    expect(helpdesk).to_not have_received(:ticket_details)
  end

  it "should process a response if the reference isn't valid" do
    helpdesk = double('Helpdesk', ticket_details: { status: :pending, replies: [] })
    allow(Helpdesk).to receive(:new).and_return(helpdesk)

    ProcessTicketResponse.new.perform(ticket.reference)
    expect(helpdesk).to have_received(:ticket_details)
  end

  it 'should process the replies' do
    reply = { id: 'REPLY1', html_body: 'Test', body: 'TEST', created_at: Time.now,
              author: 'Test', author_email: 'tester@test.com' }
    helpdesk = double('Helpdesk', ticket_details: { status: :pending, replies: [reply] })
    allow(Helpdesk).to receive(:new).and_return(helpdesk)

    expect { ProcessTicketResponse.new.perform(ticket.reference) }.to change { TicketReply.count }.by(1)
    expect(helpdesk).to have_received(:ticket_details)
  end
end
