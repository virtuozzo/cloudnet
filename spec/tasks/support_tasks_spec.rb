require 'rails_helper'

describe SupportTasks do
  it 'should create a new support ticket' do
    user = FactoryGirl.create(:user_onapp)
    server = FactoryGirl.create(:server)
    helpdesk = double('Helpdesk')
    allow(Helpdesk).to receive(:new).and_return(helpdesk)
    allow(helpdesk).to receive(:new_ticket).and_return(true)
    
    Sidekiq::Testing.inline! do
      SupportTasks.new.perform(:notify_server_validation, user, [server])
    end
    
    expect(Ticket.count).to eq(1)
    expect(helpdesk).to have_received(:new_ticket)
  end
end
