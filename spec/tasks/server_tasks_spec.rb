require 'rails_helper'

describe ServerTasks do
  before :each do
    allow_any_instance_of(Server).to receive(:supports_multiple_ips?).and_return(false)
  end

  it 'sets the correct state when refreshing the server' do
    server = FactoryGirl.create :server
    task = ServerTasks.new
    info = {
      'ip_addresses' => [{ 'ip_address' => { 'address' => '192.168.1.1' } }],
      'locked' => false, 'cpus' => server.cpus, 'memory' => server.memory,
      'total_disk_size' => server.disk_size
    }

    info['built'] = false
    allow_any_instance_of(Squall::VirtualMachine).to receive(:show).and_return(info)
    task.perform(:refresh_server, server.user.id, server.id)
    server.reload
    expect(server.state).to eq(:building)

    info['built'] = true
    info['booted'] = false
    allow_any_instance_of(Squall::VirtualMachine).to receive(:show).and_return(info)
    task.perform(:refresh_server, server.user.id, server.id)
    server.reload
    expect(server.state).to eq(:off)

    info['built'] = true
    info['booted'] = true
    allow_any_instance_of(Squall::VirtualMachine).to receive(:show).and_return(info)
    task.perform(:refresh_server, server.user.id, server.id)
    server.reload
    expect(server.state).to eq(:on)
  end

  context 'update billing when params changed' do
    let(:server) { FactoryGirl.create :server }
    let(:account) { server.user.account }
    let(:task) { ServerTasks.new }
    let(:info) { { 'ip_addresses' => [{ 'ip_address' => { 'address' => '192.168.1.1' } }],
              'locked' => false, 'booted' => true, 'cpus' => server.cpus,
              'memory' => server.memory, 'total_disk_size' => server.disk_size } }
    before :each do
      allow_any_instance_of(Squall::VirtualMachine).to receive(:show).and_return(info)
      FactoryGirl.create :payment_receipt, account: account
    end

    context 'refresh server with billing change' do
      before :each do
        expect(AdminMailer).to receive(:notify_automatic_invoice).with(server, instance_of(Server)).
          and_return(double(deliver_now: true))
      end

      it 'creates credit_note and invoice if memory changed' do
        info['memory'] = server.memory + 1
        task.perform(:refresh_server, server.user.id, server.id)
        expect(account.invoices.count).to eq 1
        expect(account.credit_notes.count).to eq 1
        a_params = server.activities.first[:parameters]
        expect(a_params[:old_memory] < a_params[:new_memory]).to be_truthy
      end

      it 'creates credit_note and invoice if cpu changed' do
        info['cpus'] = server.cpus + 1
        task.perform(:refresh_server, server.user.id, server.id)
        expect(account.invoices.count).to eq 1
        expect(account.credit_notes.count).to eq 1
        a_params = server.activities.first[:parameters]
        expect(a_params[:old_cpus] < a_params[:new_cpus]).to be_truthy
      end

      it 'creates credit_note and invoice if disk_size changed' do
        info['total_disk_size'] = server.disk_size + 1
        task.perform(:refresh_server, server.user.id, server.id)
        expect(account.invoices.count).to eq 1
        expect(account.credit_notes.count).to eq 1
        a_params = server.activities.first[:parameters]
        expect(a_params[:old_disk_size] < a_params[:new_disk_size]).to be_truthy
      end

      it 'creates credit_note and invoice if server in edit but force update' do
        server.update(no_refresh: true)
        info['total_disk_size'] = server.disk_size + 1
        task.perform(:refresh_server, server.user.id, server.id, :force_update)
        expect(account.invoices.count).to eq 1
        expect(account.credit_notes.count).to eq 1
        a_params = server.activities.first[:parameters]
        expect(a_params[:old_disk_size] < a_params[:new_disk_size]).to be_truthy
      end
    end

    context 'refresh server with no billing change' do
      before :each do
        expect(AdminMailer).not_to receive(:notify_automatic_invoice)
      end

      it 'does not create credit_note and invoice if :monitoring task' do
        info['total_disk_size'] = server.disk_size + 1
        task.perform(:refresh_server, server.user.id, server.id, false, :monitoring)
        expect(account.invoices.count).to eq 0
        expect(account.credit_notes.count).to eq 0
        expect(server.activities).to be_empty
        server.reload
        expect(server.disk_size).to eq info['total_disk_size']
      end

      it 'does not create credit_note and invoice if server in edit' do
        server.update(no_refresh: true)
        info['total_disk_size'] = server.disk_size + 1
        task.perform(:refresh_server, server.user.id, server.id)
        expect(account.invoices.count).to eq 0
        expect(account.credit_notes.count).to eq 0
        expect(server.activities).to be_empty
      end
    end
  end

  xcontext 'against real existing server', :vcr do
    include_context :with_server

    it 'grabs the CPU usages for the server' do
      @server_task.perform(:refresh_cpu_usages, @user.id, @server.id)

      usages = ServerUsage.cpu_usages(@server)
      expect(usages).not_to be_empty
      expect(usages.first.keys.include?('created_at')).to be true
      expect(usages.first.keys.include?('cpu_time')).to be true
    end

    it 'grabs the Network usages for the server' do
      @server_task.perform(:refresh_network_usages, @user.id, @server.id)

      usages = ServerUsage.network_usages(@server)
      expect(usages).not_to be_empty
      expect(usages.first.keys.include?('created_at')).to be true
      expect(usages.first.keys.include?('data_received')).to be true
      expect(usages.first.keys.include?('data_sent')).to be true
    end

    it 'allows refreshed transactions/events of the server' do
      @server_task.perform(:refresh_events, @user.id, @server.id)
      @server.reload
      expect(@server.server_events).not_to be_empty

      # Refresh the Events again, no new records should be created
      expect { @server_task.perform(:refresh_events, @user.id, @server.id) }.to change(ServerEvent, :count).by(0)
    end

    it 'allows rebooting of the server' do
      @server_task.perform(:reboot, @user.id, @server.id)

      @server.reload
      expect(@server.state_rebooting?).to be true
      @server.wait_until_ready
      expect(@server.state_on?).to be true
    end

    it 'allows shutdown and startup of the server' do
      @server_task.perform(:shutdown, @user.id, @server.id)

      @server.reload
      expect(@server.state_shutting_down?).to be true
      @server.wait_until_ready
      expect(@server.state_off?).to be true

      @server_task.perform(:startup, @user.id, @server.id)
      @server.reload
      expect(@server.state_starting_up?).to be true
      @server.wait_until_ready
      expect(@server.state_on?).to be true
    end

    it 'allows console of a server' do
      response = @server_task.perform(:console, @user.id, @server.id)
      expect(response).to have_key(:called_in_at)
      expect(response).to have_key(:port)
      expect(response).to have_key(:remote_key)
    end

    it 'allows destroy of a server' do
      @server_task.perform(:destroy, @user.id, @server.id)
      @server.reload
      expect do
        @server_task.perform(:refresh_server, @server.user.id, @server.id)
      end.to raise_error Faraday
    end

    describe 'Editing a server' do
      it 'should change the disk size of an existing server' do
        @server.disk_size = 25
        @server.save!
        @server_task.perform(:edit, @user.id, @server.id)

        @server.wait_until_ready
        @server_task.perform(:refresh_server, @server.user.id, @server.id)
        @server.reload
        expect(@server.disk_size).to eq 25
      end

      it 'should change the resources of an existing server' do
        @server.cpus = 2
        @server.memory = 1024
        @server.save!
        @server_task.perform(:edit, @user.id, @server.id)

        @server.wait_until_ready
        @server_task.perform(:refresh_server, @server.user.id, @server.id)
        @server.reload
        expect(@server.cpus).to eq 2
        expect(@server.memory).to eq 1024
      end
    end
  end
end
