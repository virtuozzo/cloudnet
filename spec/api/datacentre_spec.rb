require 'rails_helper'

describe API do
  let(:api) {'http://api.localhost.com'}
  #let(:user) { FactoryGirl.create :user }

  describe 'Datacentre methods' do
    before :each do
      Sidekiq::Testing.fake!
      #header 'Authorization', "APIKEY 123"
      FactoryGirl.create :template # Includes creation of datacentre
    end

    it 'returns all the datacentres' do
      get "#{api}/datacentres"
      body = JSON.parse(response.body)
      datacentre = body.first
      expect(body.count).to eq 1
      expect(datacentre['provider']).to eq Location.first.provider
      expect(datacentre['templates'].count).to eq 1
      expect(datacentre['templates'].first['name']).to eq Template.first.name
    end

    it 'returns info about a particular datacentre' do
      get "#{api}/datacentres/#{Location.first.id}"
      body = JSON.parse(response.body)
      expect(body['provider']).to eq Location.first.provider
      expect(body['templates'].count).to eq 1
      expect(body['templates'].first['name']).to eq Template.first.name
    end
  end
end
