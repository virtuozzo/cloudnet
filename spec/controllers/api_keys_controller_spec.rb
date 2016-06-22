require 'rails_helper'

RSpec.describe ApiKeysController, type: :controller do
  
  before(:each) { 
    sign_in_onapp_user
    @api_key = FactoryGirl.create(:api_key, user: @current_user)
    @request.env['HTTP_REFERER'] = '/users/edit'
  }
  
  describe '#create' do
    it 'should generate a new API key' do
      post :create, api_key: {title: 'cloudnet cp'}
      assert_equal 2, ApiKey.count
      expect(flash[:notice]).to eq('API key was successfully generated')
    end
    
    it 'should not generate API key' do
      post :create, api_key: {title: ''}
      expect(flash[:alert]).to eq("Unable to add API key. Title can't be blank ")
    end
    
    it 'should not allow to create more than 3 api keys per user' do
      FactoryGirl.create_list(:api_key, 2, user: @current_user) #create 2 more
      post :create, api_key: {title: 'cloudnet new cp'}
      expect(flash[:alert]).to eq("Unable to add API key. Only 3 API keys allowed per user ")
    end
  end
  
  describe '#toggle_active' do
    it 'should toggle active status of api key' do
      expect(@api_key.active).to be_truthy
      post :toggle_active, {id: @api_key.id}
      expect(@api_key.reload.active).to be_falsey
      expect(flash[:notice]).to eq('API key was successfully disabled')
      post :toggle_active, {id: @api_key.id}
      expect(@api_key.reload.active).to be_truthy
      expect(flash[:notice]).to eq('API key was successfully enabled')
    end
  end
  
  describe '#destroy' do
    it 'should delete API key' do
      delete :destroy, { id: @api_key.id }
      assert_equal 0, ApiKey.count
      expect(flash[:notice]).to eq('API key was successfully removed')
    end
  end

end
