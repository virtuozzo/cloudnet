require 'rails_helper'

describe TicketReply do
  let (:ticket_reply) { FactoryGirl.create(:ticket_reply) }

  it 'should be a valid ticket reply' do
    expect(ticket_reply).to be_valid
  end

  it 'should be invalid if not associated with a ticket' do
    ticket_reply.ticket = nil
    expect(ticket_reply).not_to be_valid
  end

  it "should be invalid if it doesn't have a sender" do
    ticket_reply.sender = nil
    expect(ticket_reply).not_to be_valid
  end

  it "should be invalid if it doesn't have a body" do
    ticket_reply.body = nil
    expect(ticket_reply).not_to be_valid
  end

  it 'should be invalid if creating a reply on solved ticket' do
    ticket = FactoryGirl.create(:ticket)
    ticket.status = :solved

    expect { FactoryGirl.create(:ticket_reply, ticket: ticket) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
