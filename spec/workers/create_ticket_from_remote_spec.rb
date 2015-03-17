require 'rails_helper'

describe CreateTicketFromRemote do
  let(:ticket) { FactoryGirl.create(:ticket, reference: 'EXISTINGREF') }

  it 'should not do anything if the ticket reference exists' do
    helpdesk = double('Helpdesk', get_ticket: { id: 'NEWREF', subject: 'New', body: 'New',
                                                author_email: ticket.user.email, created_at: Time.now, status: :open })
    allow(Helpdesk).to receive(:new).and_return(helpdesk)

    CreateTicketFromRemote.new.perform(ticket.reference)
    expect(helpdesk).to_not have_received(:get_ticket)
  end

  it "should not create the ticket details if the user doesn't exist" do
    helpdesk = double('Helpdesk', get_ticket: { id: 'NEWREF', subject: 'New', body: 'New',
                                                author_email: 'invalid@invalid.com', created_at: Time.now, status: :open })
    allow(Helpdesk).to receive(:new).and_return(helpdesk)

    expect { CreateTicketFromRemote.new.perform('NEWREF') }.to change { Ticket.count }.by(0)
    expect(helpdesk).to have_received(:get_ticket)
  end

  it 'should create the ticket if everything is fine' do
    helpdesk = double('Helpdesk', get_ticket: { id: 'NEWREF', subject: 'New', body: 'New',
                                                author_email: ticket.user.email, created_at: Time.now, status: :open })
    allow(Helpdesk).to receive(:new).and_return(helpdesk)

    expect { CreateTicketFromRemote.new.perform('NEWREF') }.to change { Ticket.count }.by(1)
    expect(helpdesk).to have_received(:get_ticket)
  end
end
