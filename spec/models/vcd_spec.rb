require 'rails_helper'

describe VCD do
  before do
    @user = FactoryGirl.build(
      :user,
      onapp_user: 'cloudnetvcd',
      onapp_password: ENV['VCDEMO_PASS']
    )
    # Disbale creation of OnApp user
    allow(@user).to receive(:create_onapp_user)
    
    @location = FactoryGirl.create :location
    @template = Template.create!(
      location: @location,
      identifier: 254,
      vmid: 'vm-c9fc20b5-14ce-40c8-a4ed-e9c23e734bf7',
      name: 'CentOS',
      os_type: 'vCD',
      onapp_os_distro: 'vCD',
      os_distro: 'vCD'
    )
    
  end
  describe 'Creating a vApp' do
    before do
      @wizard = ServerWizard.new
      @wizard.user = @user
      @wizard.name = 'rspectest'
      @wizard.location = @location
      @wizard.template = @template
    end

    it 'should create a vapp', :vcr do
      expect(VCD.count).to eq 0
      VCD.create_vapp @wizard
      expect(VCD.count).to eq 1
    end
  end
  
  describe 'Syncing created vApps', :vcr do
    before do
      @vcd = VCD.create!(
        user: @user,
        template: @template,
        identifier: 371,
        name: 'testing'
      )
    end
    
    it 'should poll and sync associated VMs' do
      expect(Server.count).to eq 0
      @vcd.check_vms
      expect(Server.count).to eq 1
      server = Server.first
      expect(server.built).to eq true
      expect(server.state).to eq 'off'
    end
    
    it 'should sync vApp status' do
      @vcd.check_status
      expect(@vcd.status).to eq 'off'
    end
    
    it 'should poll all vCDs' do
      expect(Server.count).to eq 0
      2.times {
        VCD.poll_all
      }
      expect(Server.count).to eq 1
    end
  end
end
