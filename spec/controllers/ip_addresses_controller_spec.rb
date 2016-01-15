require 'rails_helper'

RSpec.describe IpAddressesController, :type => :controller do
  
  render_views
  
  let(:json) { JSON.parse(response.body) }
  
  describe 'on a server with multiple IP support' do
    before(:each) { 
      sign_in_onapp_user
      @server = FactoryGirl.create(:server, user: @current_user)
      @server.update(state: :on)
      @server_ip_address = FactoryGirl.create(:server_ip_address, server: @server)
    }
    
    describe '#index' do
      it 'should render the servers IP addresses list' do
        get :index, { server_id: @server.id }
        expect(response).to be_success
        expect(response).to render_template('ip_addresses/index')
      end
      
      it 'should get list of IP addresses as JSON' do
        get :index, { server_id: @server.id, format: :json }
        expect(json.collect{|ip| ip["address"]}).to include(@server_ip_address.address)
      end
    end
      
    describe '#create' do
      it 'should add a new IP address' do
        allow(AssignIpAddress).to receive(:perform_async).and_return(true)
        post :create, { server_id: @server.id }
        expect(AssignIpAddress).to have_received(:perform_async)
        expect(response).to redirect_to(server_ip_addresses_path(@server))
        expect(flash[:notice]).to eq('IP address has been requested and will be added shortly')
        @server.reload
        expect(@server.ip_addresses).to eq(2)
      end
      
      it 'should not allow more than MAX_IPS limit' do
        @server.update_attribute :ip_addresses, Server::MAX_IPS
        post :create, { server_id: @server.id }
        expect(flash[:alert]).to eq('You cannot add anymore IP addresses to this server.')
      end
    end
    
    describe '#destroy' do
      it 'should remove IP address' do
        @ip_address_tasks = double('IpAddressTasks', perform: true)
        allow(IpAddressTasks).to receive(:new).and_return(@ip_address_tasks)
        @server_ip_address.update(primary: false)
        delete :destroy, { server_id: @server.id, id: @server_ip_address.id }
        
        expect(@ip_address_tasks).to have_received(:perform)
        expect(response).to redirect_to(server_ip_addresses_path(@server))
        expect(flash[:notice]).to eq('IP address has been removed')
      end
      
      it 'should not allow to remove a primary IP address' do
        expect {
          delete :destroy, { server_id: @server.id, id: @server_ip_address.id }
        }.to raise_error(RuntimeError)
      end
    end
    
  end
  
  describe 'on a server without multiple IP support' do
    before(:each) { 
      sign_in_onapp_user
      @server = FactoryGirl.create(:server, user: @current_user)
      @server.location.update(hv_group_version: '4.0.0')
    }
    
    describe 'going to the index page' do
      it 'should redirect to dashboard' do
        get :index, { server_id: @server.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

end
