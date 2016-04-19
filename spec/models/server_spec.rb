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
  
  it 'should have a primary IP address' do
    server_ip_address = FactoryGirl.create(:server_ip_address, server: server)
    expect(server.primary_ip_address).to eq('123.456.789.1')
  end
  
  it 'should be false for servers that are building' do
    expect(server.can_add_ips?).to eq(false)
  end
  
  it 'should be true for locations with multiple IP compatibility' do
    server.state = :on
    expect(server.can_add_ips?).to eq(true)
  end
  
  it 'should be true for locations with multiple IP compatibility' do
    expect(server.supports_multiple_ips?).to eq(true)
  end
  
  it 'should be true for locations with manual backup compatibility' do
    expect(server.supports_manual_backups?).to eq(true)
  end
  
  it 'should be false for older locations without multiple IP compatibility' do
    server.location.hv_group_version = '4.0.0'
    expect(server.supports_multiple_ips?).to eq(false)
  end

  describe 'Notifying of stuck states', type: :mailer  do
    def refresh_server
      ServerTasks.new.perform(:refresh_server, server.user.id, server.id)
    end

    before :each do
      @squall = double
      allow(Squall::VirtualMachine).to receive(:new).and_return(@squall)
      allow(Squall::IpAddressJoin).to receive(:new).and_return(@squall)
      allow(@squall).to receive(:show).and_return({})
      allow(@squall).to receive(:list).and_return({})
      # Simulate creating the server 1 hour ago.
      # Notifications should be triggered because the server has been building for longer
      # than Server::MAX_TIME_FOR_INTERMEDIATE_STATES
      server.update_attributes created_at: Time.zone.now - 1.hour
    end

    it 'should notify when a server has been building for an hour' do
      refresh_server
      email = ActionMailer::Base.deliveries.find do |e|
        e.subject =~ /Server stuck in intermediate stat/
      end
      expect(email.body).to match(/stuck in the building state/)
      expect(email.body).to match(/#{server.identifier}/)
    end

    it 'should only notify once' do
      5.times { refresh_server }
      emails = ActionMailer::Base.deliveries.select do |e|
        e.subject =~ /Server stuck in intermediate stat/
      end
      expect(emails.count).to eq 1
    end

    it 'should mark a server as unstuck after being stuck' do
      refresh_server
      server.reload
      expect(server.stuck).to be true

      allow(@squall).to receive(:show).and_return(
        'locked' => false,
        'booted' => true
      )

      refresh_server
      server.reload
      expect(server.stuck).to be false
    end
  end
  
  it 'should return and cache provisioner roles' do
    Rails.cache.clear
    provisioner_tasks = double(DockerProvisionerTasks)
    allow(DockerProvisionerTasks).to receive(:new).and_return(provisioner_tasks)
    allow(provisioner_tasks).to receive(:roles).and_return(
      OpenStruct.new({body: '["docker", "mysql", "mongodb"]'})
    )
    roles = Server.provisioner_roles
    expect(roles.size).to eq 3
    expect(Rails.cache.read("provisioner_roles")).to eq(roles)
  end
end
