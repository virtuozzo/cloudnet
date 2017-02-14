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
        allow_any_instance_of(CreateServer).to receive_messages(process: { 'id' => '12345', 'identifier' => 'abc123', 'memory' => 1024, 'cpus' => 2, 'disk_size' => 10 })
        allow(MonitorServer).to receive(:perform_async).and_return(true)
        # allow_any_instance_of(ServerWizard).to receive(:save_server_details).and_return(@server)
        allow_any_instance_of(Account).to receive(:card_fingerprints).and_return(['abcd12345'])
        helpdesk = double('Helpdesk', new_ticket: true)
        allow(Helpdesk).to receive(:new).and_return(helpdesk)
        allow(helpdesk).to receive(:new_ticket).and_return(true)
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
        expect(response).to redirect_to(server_path(Server.last.id))
      end
      
      it 'should create server with SSH keys installed' do
        ssh_key = FactoryGirl.create(:key)
        expect(PaymentReceipt).to receive(:charge_account)
          .with(@payment_receipts, @invoice.total_cost)
          .and_return(Hash[@payment_receipts.collect { |p| [p.id, p.remaining_cost] }])
        
        session[:server_wizard_params] = {
          cpus: @wizard.cpus,
          memory: @wizard.memory,
          disk_size: @wizard.disk_size,
          location_id: @wizard.location.id
        }
        params = { server_wizard: { current_step: 2, name: @wizard.name, hostname: @wizard.hostname, template_id: @wizard.template_id, memory: @wizard.memory, cpus: @wizard.cpus, disk_size: @wizard.disk_size, ssh_key_ids: [ssh_key.id.to_s] }, template: @wizard.template_id}
        expect {
          post :create, params
        }.to change(InstallKeys.jobs, :size).by(1)
      end
      
      it 'should create server and put in validation' do
        FactoryGirl.create(:billing_card, account: @current_user.account, fraud_score: 10.0, fraud_verified: true)
        RiskyCard.create(fingerprint: 'abcd12345', account: @current_user.account)
        
        session[:server_wizard_params] = {
          cpus: @wizard.cpus,
          memory: @wizard.memory,
          disk_size: @wizard.disk_size,
          location_id: @wizard.location.id
        }
        params = { server_wizard: { current_step: 2, name: @wizard.name, hostname: @wizard.hostname, template_id: @wizard.template_id, memory: @wizard.memory, cpus: @wizard.cpus, disk_size: @wizard.disk_size }, template: @wizard.template_id}
        post :create, params

        new_server = Server.last
        expect(new_server.validation_reason).to eq(5)
        expect(flash[:notice]).to eq('Server successfully created but has been placed under validation. A support ticket has been created for you. A support team agent will review and reply to you shortly.')
        expect(RiskyIpAddress.count).to eq(2)
        expect(RiskyCard.count).to eq(1)
        expect(response).to redirect_to(server_path(new_server.id))
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
