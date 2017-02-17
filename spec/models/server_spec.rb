require 'rails_helper'
require 'models/concerns/taggable_shared'

describe Server do
  let(:server) {FactoryGirl.create(:server, memory: 1024, cpus: 1, disk_size: 20)}
  it_behaves_like 'taggable'

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
  
  it 'should queue install keys' do
    key = FactoryGirl.create(:key)
    expect {
      server.install_ssh_keys([key.id.to_s])
    }.to change(InstallKeys.jobs, :size).by(1)
  end

  describe 'Notifying of stuck states', type: :mailer  do
    def refresh_server
      ServerTasks.new.perform(:refresh_server, server.user.id, server.id)
    end

    before :each do
      @squall = double
      allow(Squall::VirtualMachine).to receive(:new).and_return(@squall)
      allow(Squall::IpAddressJoin).to receive(:new).and_return(@squall)
      allow(@squall).to receive(:show).and_return({'memory' => 512, 'cpus' => 1, 'disk_size' => 20})
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
        'booted' => true,
        'memory' => 512,
        'cpus' => 1,
        'disk_size' => 20
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

  it 'calculates forecasted revenue for server' do
    server.user.account.coupon = FactoryGirl.create(:coupon)
    expect(server.forecasted_revenue).to eq 55722240
  end

  describe "notify faulty server" do
    context 'more than 1 day after creation' do
      before :each do
        server.update_attributes created_at: Time.zone.now - (1.day + 1.hour)
      end

      it "notifies when no storage" do
        expect(AdminMailer).to receive(:notify_faulty_server).with(server, true, false).
          and_return(double(deliver_now: true))
        server.notify_fault(true, false)
        expect(server.fault_reported_at).to be
        expect(server.activities.count).to eq 1
        expect(server.activities.first.parameters).to eq :no_disk=>true, :no_ip=>false
        expect(server.tag_labels).to eq ['no_disk']
      end

      it "notifies when no ip" do
        expect(AdminMailer).to receive(:notify_faulty_server).with(server, false, true).
          and_return(double(deliver_now: true))
        server.notify_fault(false, true)
        expect(server.fault_reported_at).to be
        expect(server.activities.count).to eq 1
        expect(server.activities.first.parameters).to eq :no_disk=>false, :no_ip=>true
        expect(server.tag_labels).to eq ['no_ip']
      end

      it "notifies when no storage and no ip" do
        expect(AdminMailer).to receive(:notify_faulty_server).with(server, true, true).
          and_return(double(deliver_now: true))
        server.notify_fault(true, true)
        expect(server.fault_reported_at).to be
        expect(server.activities.count).to eq 1
        expect(server.activities.first.parameters).to eq :no_disk=>true, :no_ip=>true
        expect(server.tag_labels).to include('no_disk', 'no_ip')
      end

      it 'doesnt notify when storage and ip exist' do
        expect(AdminMailer).not_to receive(:notify_faulty_server)
        server.notify_fault(false, false)
        expect(server.fault_reported_at).not_to be
        expect(server.activities).to be_empty
      end

      it "notifies once" do
        expect(AdminMailer).to receive(:notify_faulty_server).with(server, true, true).
          and_return(double(deliver_now: true)).once

        server.notify_fault(true, true)
        report_time = server.reload.fault_reported_at
        server.notify_fault(true, true)
        expect(server.fault_reported_at).to eq report_time

        # pass less time than REPORT_FAULTY_VM_EVERY
        time_reported = Time.zone.now - Server::REPORT_FAULTY_VM_EVERY + 1.hour
        server.update_attributes fault_reported_at: time_reported
        time_reported = server.reload.fault_reported_at # postgress time resolution issue
        expect(server).not_to receive(:update_attribute)
        server.notify_fault(true, true)
        expect(server.fault_reported_at).to eq time_reported

        expect(server.activities.count).to eq 1
        expect(server.activities.first.parameters).to eq :no_disk=>true, :no_ip=>true
      end

      it 're-notifies after REPORT_FAULTY_VM_EVERY time' do
        expect(AdminMailer).to receive(:notify_faulty_server).with(server, true, true).
          and_return(double(deliver_now: true)).twice

        server.notify_fault(true, true)
        expect(server.fault_reported_at).to be

        # simulating last notification sent more than REPORT_FAULTY_VM_EVERY ago
        report_time_1 = Time.zone.now - (Server::REPORT_FAULTY_VM_EVERY + 1.hour)
        server.update_attributes fault_reported_at: report_time_1
        report_time_1 = server.reload.fault_reported_at # postgress time resolution issue
        server.notify_fault(true, true)
        expect(server.fault_reported_at).not_to eq report_time_1
        report_time_2 = server.reload.fault_reported_at

        # no more notifications before next REPORT_FAULTY_VM_EVERY
        server.notify_fault(true, true)
        expect(server.fault_reported_at).to eq report_time_2
        expect(server.activities.count).to eq 2
      end
    end

    context 'less than 1 day of creation' do
      it 'doesnt notify when no storage or no ip' do
        expect(AdminMailer).not_to receive(:notify_faulty_server)
        server.notify_fault(true, true)
        expect(server.fault_reported_at).not_to be
        expect(server.activities).to be_empty
      end

      it 'sets and removes tags' do
        server.notify_fault(true, true)
        expect(server.tag_labels).to include('no_disk', 'no_ip')
        server.notify_fault(false, true)
        expect(server.tag_labels).to include('no_ip')
        server.notify_fault(false, false)
        expect(server.tag_labels).to be_empty
      end
    end
  end
end
