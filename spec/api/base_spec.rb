require 'rails_helper'

describe API do
  let(:api) {'http://api.localhost.com'}
  
  describe 'Root methods' do
    it 'returns the current version' do
      get "#{api}/version"
      
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body['version']).to eq ENV['API_VERSION']
    end

    it 'returns general info about the API' do
      FactoryGirl.create(:location)
      worker_size = Sidekiq::ProcessSet.new.size rescue 0
      get "#{api}/"
      
      body = JSON.parse(response.body)
      expect(
        body['status']['worker']
      ).to eq worker_size
      
      expect(
        body['status']['datacenters']
      ).to eq 1
    end
  end
end
