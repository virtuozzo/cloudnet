require 'rails_helper'
require 'mail'

describe Ticket do
  let (:ticket) { FactoryGirl.create(:ticket) }

  it 'should have a valid ticket' do
    expect(ticket).to be_valid
  end

  it 'is invalid if not associated with a user' do
    ticket.user = nil
    expect(ticket).not_to be_valid
  end

  it 'is invalid if there is no body text in the ticket' do
    ticket.body = ''
    expect(ticket).not_to be_valid
  end

  it 'is invalid if there is no subject text in the ticket' do
    ticket.subject = ''
    expect(ticket).not_to be_valid
  end

  describe 'ticket references' do
    it "doesn't have a reference by default" do
      expect(ticket.reference).to be_nil
    end

    it 'should allow assignment of a reference' do
      ticket.reference = '1234'
      expect(ticket.reference).to eq('1234')
    end
  end

  describe 'ticket departments' do
    let (:departments) { Helpdesk.departments }

    it 'should have a department set by default (the first of the list)' do
      expect(ticket).to be_valid
      expect(ticket.department).to eq(departments.keys.first)
    end

    it 'should not allow the setting of an invalid department' do
      ticket.department = :invalid_department
      expect(ticket).not_to be_valid
    end
  end

  describe 'ticket server' do
    it 'should be valid with an empty server' do
      ticket.server = nil
      expect(ticket).to be_valid
    end
  end

  describe 'ticket statuses' do
    before(:each) { ticket.save! }

    it 'should have a status of new by default' do
      expect(ticket.status).to eq(:new)
    end

    it 'should allow assignments of statuses' do
      ticket.status = :pending
      expect(ticket.status).to eq(:pending)
    end
  end

  describe 'ticket replies' do
    it "shouldn't have any replies by default" do
      expect(ticket.ticket_replies).to be_empty
    end

    it 'should delete replies when a ticket is destroyed' do
      reply = FactoryGirl.create(:ticket_reply, ticket: ticket)
      expect { ticket.destroy }.to change(TicketReply, :count).by(-1)
    end
  end
end
