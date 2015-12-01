require 'rails_helper'

describe ServerWizardsController do
  
  before(:each) do
    sign_in_onapp_user
    @account  = @current_user.account
    @wizard   = FactoryGirl.create(:server_wizard, :with_wallet, user: @current_user)
    @invoice  = Invoice.generate_prepaid_invoice([@wizard], @account)
    @server   = FactoryGirl.create(:server)
    @payment_receipts = @account.payment_receipts.with_remaining_cost
  end
  
  describe 'creating server' do
    
    context 'before creating' do      
      it 'should preset the server wizard to step 2' do
        expect_any_instance_of(ServerWizardsController).to receive(:step2).and_call_original
        allow(Analytics).to receive(:track)
        
        params = { cpu: 1, mem: 512, disk: 20, id: @wizard.location.id }
        get :new, params
      end
    end

    context 'submitting a create' do
      before :each do
        allow_any_instance_of(CreateServer).to receive_messages(process: { 'id' => '12345' })
        allow(MonitorServer).to receive(:perform_async).and_return(true)
        allow_any_instance_of(ServerWizard).to receive(:save_server_details).and_return(@server)
      end

      it 'should create server using Wallet funds' do
        expect(PaymentReceipt).to receive(:charge_account)
          .with(@payment_receipts, @invoice.total_cost)
          .and_return(Hash[@payment_receipts.collect { |p| [p.id, p.remaining_cost] }])
        
        session[:server_wizard_params] = {
          cpus: @wizard.cpus,
          memory: @wizard.memory,
          disk_size: @wizard.disk_size,
          location_id: @wizard.location.id
        }
        params = { server_wizard: { current_step: 2, name: @wizard.name, hostname: @wizard.hostname, template_id: @wizard.template_id, memory: @wizard.memory, cpus: @wizard.cpus, disk_size: @wizard.disk_size }, template: @wizard.template_id}
        post :create, params

        expect(flash[:notice]).to eq('Server successfully created and will be booted shortly')
        expect(response).to redirect_to(server_path(@server.id))
      end

      it 'should handle errors if creating server fails' do
        expect_any_instance_of(SentryLogging).to receive(:raise).with(instance_of(Faraday::Error::ClientError))        
        allow_any_instance_of(CreateServer).to receive(:process).and_raise(Faraday::Error::ClientError.new('Test'))

        session[:server_wizard_params] = {
          cpus: @wizard.cpus,
          memory: @wizard.memory,
          disk_size: @wizard.disk_size,
          location_id: @wizard.location.id
        }
        params = { server_wizard: { current_step: 2, name: @wizard.name, hostname: @wizard.hostname, template_id: @wizard.template_id, memory: @wizard.memory, cpus: @wizard.cpus, disk_size: @wizard.disk_size }, template: @wizard.template_id}
        post :create, params
        
        expect(response).to have_http_status(:ok)
      end
    end
  end
end