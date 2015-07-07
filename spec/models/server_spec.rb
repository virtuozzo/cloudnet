require 'rails_helper'

describe Server do
  let(:server) { FactoryGirl.create(:server) }

  it 'has a valid server' do
    expect(server).to be_valid
  end

  it 'is invalid without an identifier' do
    server.identifier = ''
    expect(server).not_to be_valid
  end

  it 'is invalid without a name' do
    server.name = ''
    expect(server).not_to be_valid
  end

  it 'should be in the off state by default' do
    expect(server.state_building?).to be true
  end

  it 'is invalid without a valid user' do
    server.user = nil
    expect(server).not_to be_valid
  end

  it 'is invalid without a location' do
    server.location = nil
    expect(server).not_to be_valid
  end

  it 'is invalid without a template' do
    server.template = nil
    expect(server).not_to be_valid
  end

  describe 'Notifying of stuck states', type: :mailer  do
    it 'should notify when a server has been building for an hour' do
      # Simulate creating the server 1 hour ago
      server.created_at = Time.zone.now - 1.hour
      server.save!

      # Refresh the server's state from the API without any state change
      squall = double
      allow(Squall::VirtualMachine).to receive(:new).and_return(squall)
      allow(squall).to receive(:show).and_return(
        {}
      )
      ServerTasks.new.perform(:refresh_server, server.user.id, server.id)

      # Notifications should be triggered because the server has been building for longer
      # than Server::MAX_TIME_FOR_INTERMEDIATE_STATES
      email = ActionMailer::Base.deliveries[1].body
      expect(email).to match(/stuck in the building stat/)
      expect(email).to match(/#{server.identifier}/)
    end
  end
end
