require 'rails_helper'

describe ServerWizard do
  let(:server_wizard) { FactoryGirl.create(:server_wizard, :with_wallet) }

  it 'should be valid' do
    expect(server_wizard).to be_valid
    expect(server_wizard.id).to be_nil
  end

  it 'should have two steps' do
    expect(server_wizard.total_steps).to eq(2)
  end
  
  it 'should have three steps' do
    server_wizard = FactoryGirl.create(:server_wizard)
    expect(server_wizard.total_steps).to eq(3)
  end

  it "isn't valid without a location" do
    server_wizard.current_step = 2
    server_wizard.location_id = nil
    expect(server_wizard).not_to be_valid
  end

  it "isn't valid without a template" do
    server_wizard.current_step = 2
    server_wizard.template_id = nil
    expect(server_wizard).not_to be_valid
  end

  it 'should be invalid without memory' do
    server_wizard.memory = nil
    expect(server_wizard).not_to be_valid
  end

  it 'should be invalid without cpus' do
    server_wizard.cpus = nil
    expect(server_wizard).not_to be_valid
  end

  it 'should be invalid without disk size' do
    server_wizard.disk_size = nil
    expect(server_wizard).not_to be_valid
  end

  it "should be invalid if template doesn't exist" do
    server_wizard.current_step = 2
    server_wizard.template_id = -1
    expect(server_wizard).not_to be_valid
  end

  it 'should not allow a template from a different location' do
    server_wizard.current_step = 2
    location1 = FactoryGirl.create(:location)
    location2 = FactoryGirl.create(:location)
    template = FactoryGirl.create(:template, location: location1)

    server_wizard.location_id = location1.id
    server_wizard.template_id = template.id
    expect(server_wizard).to be_valid
    
    server_wizard_new = FactoryGirl.create(:server_wizard, :with_wallet)
    server_wizard_new.location_id = location2.id
    server_wizard_new.template_id = template.id
    expect(server_wizard_new).not_to be_valid
  end

  it 'should validate the name of the server' do
    server_wizard.current_step = 2
    server_wizard.name = 'a'
    expect(server_wizard).not_to be_valid
    server_wizard.name = ''
    expect(server_wizard).not_to be_valid
    server_wizard.name = 'a' * 50
    expect(server_wizard).not_to be_valid
    server_wizard.name = 'a' * 48
    expect(server_wizard).to be_valid
    server_wizard.name = 'aa'
    expect(server_wizard).to be_valid
  end

  it 'should autocorrect hostname of server' do
    server_wizard.current_step = 2
    server_wizard.hostname = 'http://google.com'
    expect(server_wizard.hostname).to eq('google.com')
    server_wizard.hostname = 'https://google.com'
    expect(server_wizard.hostname).to eq('google.com')
    server_wizard.hostname = 'google.com'
    expect(server_wizard.hostname).to eq('google.com')
  end

  it 'should return package id if current values are in package' do 
    middle_id = server_wizard.packages.map(&:id).min + 1
    expect(server_wizard.package_matched).to eq middle_id
    
    server_wizard.memory = 512
    expect(server_wizard.package_matched).to be_nil
  end
  
  it 'should prepare cpu/disk/memory values form params' do
    res1 = {cpus: 2, memory: 1024, disk_size: 20}
    res2 = {cpus: 0, memory: 0, disk_size: 20}
    expect(server_wizard.send(:wizard_params)).to eq res1
    server_wizard.memory = nil
    server_wizard.cpus = 0
    expect(server_wizard.send(:wizard_params)).to eq res2
  end
  
  it 'should return true if params greater then 0' do
    expect(server_wizard.params_values?).to eq true
    server_wizard.memory = nil
    server_wizard.cpus = 0
    expect(server_wizard.params_values?).to eq true
    server_wizard.disk_size = nil
    expect(server_wizard.params_values?).to eq false
    server_wizard.cpus = 'sss'
    expect(server_wizard.params_values?).to eq false
  end
  
  describe 'resource limits' do
    before(:each) { server_wizard.current_step = 2 }

    it 'should detect over provisioning of memory' do
      allow(server_wizard.user).to receive_messages(memory_max: 512)
      expect(server_wizard.user.servers.count).to eq(0)
      server_wizard.memory = 512
      server_wizard.cpus = 1
      expect(server_wizard).to be_valid

      server_wizard.memory = 1024
      expect(server_wizard).not_to be_valid
    end

    it 'should detect over provisioning of disk' do
      allow(server_wizard.user).to receive_messages(storage_max: 20)
      expect(server_wizard.user.servers.count).to eq(0)

      server_wizard.disk_size = 20
      expect(server_wizard).to be_valid
      server_wizard.disk_size = 50
      expect(server_wizard).not_to be_valid
    end
    
    it 'should detect over provisioning of cpus' do
      allow(server_wizard.user).to receive_messages(cpu_max: 5)
      expect(server_wizard.user.servers.count).to eq(0)

      server_wizard.cpus = 2
      expect(server_wizard).to be_valid
      server_wizard.cpus = 6
      expect(server_wizard).not_to be_valid
    end

    it 'detects over provisioning of vms' do
      allow(server_wizard.user).to receive_messages(vm_max: 2)
      FactoryGirl.create(:server, user: server_wizard.user)
      expect(server_wizard).to be_valid
      FactoryGirl.create(:server, user: server_wizard.user)
      expect(server_wizard).not_to be_valid
    end
    
    describe 'under provisioning' do
      before(:each) { allow(server_wizard).to receive_messages(minimum_resources: { memory: 512, cpus: 1, disk_size: 10 }) }

      it 'should detect under provisioning of cpus' do
        server_wizard.memory = 512
        server_wizard.cpus = 1
        expect(server_wizard).to be_valid
        server_wizard.cpus = 0
        expect(server_wizard).not_to be_valid
      end

    end
  end

  it 'should validate ssh key install for Windows and FreeBSD VMs' do
    server_wizard.current_step = 2
    server_wizard.ssh_key_ids = ["1"]
    expect(server_wizard).to be_valid
    
    win_server_wizard = FactoryGirl.create(:server_wizard, :with_windows_template)
    win_server_wizard.current_step = 2
    expect(win_server_wizard).to be_valid
    
    win_server_wizard.ssh_key_ids = ["1"]
    expect(win_server_wizard).not_to be_valid
    
    fbsd_server_wizard = FactoryGirl.create(:server_wizard, :with_freebsd_template)
    fbsd_server_wizard.current_step = 2
    expect(fbsd_server_wizard).to be_valid
    
    fbsd_server_wizard.ssh_key_ids = ["1"]
    expect(fbsd_server_wizard).not_to be_valid
  end

  describe 'template limits' do
    before(:each) do
      server_wizard.current_step = 2
      @template = FactoryGirl.create(:template, min_memory: 256 * 2, min_disk: 5 * 2)
      @provisioner_template = FactoryGirl.create(:template, min_memory: 256 * 2, min_disk: 5 * 2, os_distro: 'docker', location: server_wizard.location)
      allow(server_wizard).to receive_messages(minimum_resources: { memory: 256, cpus: 1, disk_size: 5 }, template: @template)
      server_wizard.cpus = 3
      server_wizard.memory = @template.min_memory
      server_wizard.disk_size = 50
    end

    it 'should detect under provisioning of memory' do
      server_wizard.memory = @template.min_memory
      expect(server_wizard).to be_valid
      server_wizard.memory = @template.min_memory - 1
      expect(server_wizard).not_to be_valid
    end

    it 'should detect under provisioning of disk' do
      server_wizard.disk_size = 50
      expect(server_wizard).to be_valid
      server_wizard.disk_size = @template.min_disk - 1
      expect(server_wizard).not_to be_valid
    end
    
    it 'should detect invalid template for provisioner' do
      server_wizard.provisioner_role = 'redis'
      server_wizard.template_id = @template.id
      expect(server_wizard).not_to be_valid
      server_wizard.template_id = @provisioner_template.id
      expect(server_wizard).to be_valid
    end
  end

  describe 'payment step' do
    before(:each) do
      server_wizard.current_step = 3
    end

    it 'should allow valid Wallet funds' do
      server_wizard = FactoryGirl.create(:server_wizard, :with_wallet)
      expect(server_wizard).to be_valid
    end

    it "shouldn't allow an empty Wallet" do
      server_wizard = FactoryGirl.create(:server_wizard)
      expect(server_wizard).not_to be_valid
    end
  end
end
