require 'rails_helper'

describe API do
  let(:api) {'http://api.localhost.com'}
  let(:user) { FactoryGirl.create :user }
  let(:api_key) { FactoryGirl.create :api_key, user: user}
  let(:encoded) { Base64.encode64("#{user.email}:#{api_key.key}") }
  
  describe 'Servers methods' do
    it_behaves_like "api authentication", "servers/1"

    it 'returns all servers for a current user' do
      FactoryGirl.create_list :server, 3, user: user
      get "#{api}/servers", nil, 'Authorization': "Basic #{encoded}"
      body = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(body).to be_an Array
      expect(body.count).to eq user.servers.count
      expect(body.first['template']).to be_a Hash
      expect(body.first['ip_addresses']).to be_an Array
    end
    
    it 'returns a server if a user is authorized' do
      list = FactoryGirl.create_list :server, 3, user: user
      server_id = list[0].id
      get "#{api}/servers/#{server_id}", nil, 'Authorization': "Basic #{encoded}"
      body = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(body).to be_a Hash
      expect(body['id']).to eq server_id
    end
    
    it 'returns forbidden if a user is not authorized' do
      list = FactoryGirl.create_list :server, 3, user: user
      non_authorized_server = FactoryGirl.create :server
      get "#{api}/servers/#{non_authorized_server.id}", nil, 'Authorization': "Basic #{encoded}"
      body = JSON.parse(response.body)
      expect(response.status).to eq 404
    end
  end
end
