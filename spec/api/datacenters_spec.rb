require 'rails_helper'

describe API do
  let(:api) {'http://api.localhost.com'}
  let(:user) { FactoryGirl.create :user }
  let(:api_key) { FactoryGirl.create :api_key, user: user}
  let(:encoded) { Base64.encode64("#{user.email}:#{api_key.key}") }
  
  describe 'Datacenters methods' do
    before :each do
      FactoryGirl.create :template # Includes creation of Location (datacenter)
    end

    it_behaves_like "api authentication", "datacenters"

    it 'returns all the datacenters' do
      get "#{api}/datacenters", nil, 'Authorization': "Basic #{encoded}"
      body = JSON.parse(response.body)
      datacenter = body.first
      expect(body.count).to eq Location.count
      expect(datacenter['provider']).to eq Location.first.provider
      expect(datacenter['templates'].count).to eq 1
      expect(datacenter['templates'].first['name']).to eq Template.first.name
    end

    it 'returns info about a particular datacenter' do
      get "#{api}/datacenters/#{Location.first.id}", nil, 'Authorization': "Basic #{encoded}"
      body = JSON.parse(response.body)
      expect(body['provider']).to eq Location.first.provider
      expect(body['templates'].count).to eq 1
      expect(body['templates'].first['name']).to eq Template.first.name
    end
  end
end
