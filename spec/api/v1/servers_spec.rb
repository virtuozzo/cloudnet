require 'rails_helper'

describe API do
  let(:api) {'http://api.localhost.com'}
  let(:user) { FactoryGirl.create :user }
  let(:api_key) { FactoryGirl.create :api_key, user: user}
  let(:encoded) { Base64.encode64("#{user.email}:#{api_key.key}") }
  let(:good_header) { {"Authorization": "Basic #{encoded}", "Accept-Version": "v1"} }
  let!(:server_list) { FactoryGirl.create_list :server, 3, user: user }
  let(:server_id) { server_list[0].id }
  describe 'Servers methods' do
    it_behaves_like "api authentication", "servers/1"

    it 'returns all servers for a current user' do
      get "#{api}/servers", nil, good_header
      body = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(body).to be_an Array
      expect(body.count).to eq user.servers.count
      expect(body.first['template']).to be_a Hash
      expect(body.first['ip_addresses']).to be_an Array
    end
    
    context 'GET /server/:id' do
      it 'returns a server if a user is authorized' do
        get "#{api}/servers/#{server_id}", nil, good_header
        body = JSON.parse(response.body)
        expect(response.status).to eq 200
        expect(body).to be_a Hash
        expect(body['id']).to eq server_id
      end
    
      it 'returns "not found" if a user is not authorized' do
        non_authorized_server = FactoryGirl.create :server
        get "#{api}/servers/#{non_authorized_server.id}", nil, good_header
        body = JSON.parse(response.body)
        expect(response.status).to eq 404
      end
    end
    
    context 'DELETE /server/:id' do
      it 'destroys server if a user is authorized' do
        server_task_double = double('ServerTask', perform: true)
        expect(ServerTasks).to receive(:new).and_return(server_task_double)
        expect(user.account.credit_notes.count).to eq 0
        expect {delete "#{api}/servers/#{server_id}", nil, good_header}. to change {Server.count}.by(-1)
        expect(user.account.credit_notes.count).to eq 1
        body = JSON.parse(response.body)
        expect(response.status).to eq 200
        expect(body['message']).to eq "Server #{server_id} has been scheduled for destruction"
      end
      
      it 'returns "not found" if a user is not authorized' do
        non_authorized_server = FactoryGirl.create :server
        delete "#{api}/servers/#{non_authorized_server.id}", nil, good_header
        body = JSON.parse(response.body)
        expect(response.status).to eq 404
      end
    end
    
  end
end
