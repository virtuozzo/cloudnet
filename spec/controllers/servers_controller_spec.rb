require 'rails_helper'

describe ServersController do
  describe 'as a signed in user who is active' do
    before(:each) { sign_in_onapp_user }
    let(:server) { FactoryGirl.create(:server, user: @current_user) }

    describe 'going to the index page' do
      it 'should render the dashboard index page' do
        get :index
        expect(response).to be_success
        expect(response).to render_template('servers/index')
      end

      it 'should assign @servers to display for the current user' do
        servers = FactoryGirl.create_list(:server, 5, user: @current_user)
        get :index
        expect(assigns(:servers)).to eq(servers)
      end
    end

    describe 'going to the server show page' do
      it 'should render the show template' do
        get :show, id: server.id
        expect(response).to render_template('servers/show')
      end

      it 'should show information about the server' do
        get :show, id: server.id
        expect(assigns(:server)).to eq(server)
      end
    end

    describe 'events' do
      it 'should render the events template if json' do
        get :events, id: server.id
        expect(response).to be_success
      end
    end

    describe 'server actions' do
      before(:each) do
        @server_tasks = double('ServerTasks', perform: true)
        allow(ServerTasks).to receive(:new).and_return(@server_tasks)
        allow(MonitorServer).to receive(:perform_in).and_return(true)
        request.env['HTTP_REFERER'] = servers_path
        Sidekiq::Worker.clear_all
      end

      it 'should allow rebooting of a server' do
        post :reboot, id: server.id
        expect(@server_tasks).to have_received(:perform)
        expect(MonitorServer).to have_received(:perform_in)
        expect(response).to redirect_to(servers_path)
        assert_equal 1, CreateSiftEvent.jobs.size
      end

      it 'should show an error if reboot schedule failed' do
        allow(@server_tasks).to receive(:perform).and_raise(Faraday::Error::ClientError.new('Test'))
        post :reboot, id: server.id
        expect(response).to redirect_to(servers_path)
        expect(flash[:warning]).to eq('Could not schedule reboot server. Please try again later')
      end

      it 'should allow shutdown of a server' do
        post :shut_down, id: server.id
        expect(@server_tasks).to have_received(:perform)
        expect(MonitorServer).to have_received(:perform_in)
        expect(response).to redirect_to(servers_path)
        assert_equal 1, CreateSiftEvent.jobs.size
      end

      it 'should show an error if shutdown schedule failed' do
        expect_any_instance_of(SentryLogging).to receive(:raise).with(instance_of(Faraday::Error::ClientError))
        allow(@server_tasks).to receive(:perform).and_raise(Faraday::Error::ClientError.new('Test'))
        post :shut_down, id: server.id
        expect(response).to redirect_to(servers_path)
        expect(flash[:warning]).to eq('Could not schedule shutdown server. Please try again later')
      end

      it 'should allow startup of a server' do
        post :start_up, id: server.id
        expect(@server_tasks).to have_received(:perform)
        expect(MonitorServer).to have_received(:perform_in)
        expect(response).to redirect_to(servers_path)
        assert_equal 1, CreateSiftEvent.jobs.size
      end

      it 'should show an error if startup schedule failed' do
        expect_any_instance_of(SentryLogging).to receive(:raise).with(instance_of(Faraday::Error::ClientError))
        allow(@server_tasks).to receive(:perform).and_raise(Faraday::Error::ClientError.new('Test'))
        post :start_up, id: server.id
        expect(response).to redirect_to(servers_path)
        expect(flash[:warning]).to eq('Could not schedule starting up of server. Please try again later')
      end
      
      it 'should rebuild network of a server' do
        server.update(state: :on)
        rebuild_network = double('RebuildNetwork', process: true)
        allow(RebuildNetwork).to receive(:new).and_return(rebuild_network)
        
        post :rebuild_network, id: server.id
        expect(rebuild_network).to have_received(:process)
        expect(flash[:notice]).to eq('Network rebuild has been scheduled')
      end
      
      it 'should reset password of a server' do
        server.update(state: :on)
        reset_password = double('ResetRootPassword', process: true)
        allow(ResetRootPassword).to receive(:new).and_return(reset_password)
        
        post :reset_root_password, id: server.id
        expect(reset_password).to have_received(:process)
        expect(flash[:notice]).to eq('Password has been reset')
      end

      describe 'editing server' do
        context 'before editing' do
          it 'should preset the server wizard to step 2' do
            expect_any_instance_of(ServersController).to receive(:step2).and_call_original
            allow(Analytics).to receive(:track)
            get :edit, id: server.id
          end
        end

        context 'submitting an edit' do
          before :each do
            @edit_server_task = double('EditServerTask', edit_server: true)
            allow(EditServerTask).to receive_messages(new: @edit_server_task)
            
            @card = FactoryGirl.create :billing_card, account: @current_user.account
            @payments = double('Payments', auth_charge: { charge_id: 12_345 }, capture_charge: { charge_id: 12_345 })
            @server = FactoryGirl.create(
              :server,
              user: @current_user,
              cpus: 1,
              memory: 1024,
              disk_size: 20
            )
            
            @old_server_params = {"cpus"=>@server.cpus, 
                                  "memory"=>@server.memory,
                                  "name"=>@server.name}
            # We don't actually destroy the old server to make the edit, we just need 2 server
            # entities so that we can generate an invoice for both in order to figure out the price
            # difference
            @new_server = FactoryGirl.create(
              :server,
              user: @current_user,
              cpus: 3,
              memory: 1512,
              disk_size: 20
            )
            
            @payment_receipts = FactoryGirl.create_list(:payment_receipt, 2, account: @current_user.account)
                                 
            allow(Payments).to receive_messages(new: @payments)
            allow(MonitorServer).to receive(:perform_async).and_return(true)
            Sidekiq::Testing.inline!
          end
          
          after(:each) do
            Sidekiq::Testing.fake!
          end

          it 'should trigger the edit server task' do
            # Calculate the amount of the new charge
            invoice_for_old_server  = Invoice.generate_prepaid_invoice([@server], @current_user.account)
            invoice_for_new_server  = Invoice.generate_prepaid_invoice([@new_server], @current_user.account)
            cost_difference_milli = invoice_for_new_server.total_cost - invoice_for_old_server.total_cost
            cost_difference_cents = Invoice.milli_to_cents(cost_difference_milli)

            # There can be a micro discrepnacy between the cost we caclulate here and the cost
            # calculated in the code, due to rounding. So we use Invoice.pretty_total as the actual
            # macther
            RSpec::Matchers.define :pretty_total do |expected|
              match { |actual| Invoice.pretty_total(expected) == Invoice.pretty_total(actual) }
            end
            expect(@payments).to_not receive(:auth_charge)

            expect(@edit_server_task).to receive(:edit_server)
            session[:server_wizard_params] = {
              cpus: @server.cpus,
              memory: @server.memory,
              disk_size: @server.disk_size
            }
            params = { id: @server.id, server_wizard: { current_step: 2, name: @new_server.name, hostname: @new_server.hostname, template_id: @server.template_id, memory: @new_server.memory, cpus: @new_server.cpus, disk_size: @new_server.disk_size }}
            post :edit, params
            @server.reload
            expect(@server.cpus).to eq @new_server.cpus
            expect(@server.memory).to eq @new_server.memory
            expect(response).to redirect_to(server_path)
          end

          xit 'should not charge for a server that costs less' do
          end

          it 'should handle errors if updating resources fails' do
            expect_any_instance_of(SentryLogging).to receive(:raise).with(instance_of(Faraday::Error::ClientError))
            allow(@edit_server_task).to receive(:edit_server).and_raise(Faraday::Error::ClientError.new('Test'))
            expect(@payments).to_not receive(:capture_charge)
            session[:server_wizard_params] = {
              cpus: 3,
              memory: 2096,
              disk_size: 10
            }
            params = { id: @server.id, server_wizard: { current_step: 2, name: @new_server.name, hostname: @new_server.hostname, template_id: @server.template_id, memory: @new_server.memory, cpus: @new_server.cpus, disk_size: @new_server.disk_size }, template: @server.template_id }
            post :edit, params
            expect(response).to redirect_to(servers_path)
            expect(flash[:warning]).to eq('Could not schedule update of server. Please try again later')
          end
        end
      end
    end

    describe 'destroying server' do
      it 'should attempt to destroy the server' do
        destroyer = double('DestroyServerTask', process: true, :success? => true)
        allow(DestroyServerTask).to receive(:new).and_return(destroyer)

        delete :destroy, id: server.id
        expect(destroyer).to have_received(:process)
        expect(response).to redirect_to(servers_path)
      end

      it 'should return an error to the user if destroy failed' do
        destroyer = double('DestroyServerTask', process: true, :success? => false, errors: ['Tester'])
        allow(DestroyServerTask).to receive(:new).and_return(destroyer)

        delete :destroy, id: server.id
        expect(response).to redirect_to(servers_path)
        expect(flash[:warning]).to be_present
      end
    end
  end
end
