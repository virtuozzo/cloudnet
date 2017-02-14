require 'rails_helper'

RSpec.describe KeysController, :type => :controller do
  
  before(:each) { 
    sign_in_onapp_user 
    @key = FactoryGirl.create(:key, user: @current_user)
    @request.env['HTTP_REFERER'] = '/users/edit'
  }
  
  describe '#index' do
    context "with JSON format" do
      render_views
      let(:json) { JSON.parse(response.body) }
      
      it 'should render SSH keys list as JSON' do
        get :index, { format: :json }
        expect(json.collect{|key| key["title"]}).to include(@key.title)
      end
    end
  end
  
  describe '#create' do
    it 'should add a new SSH key' do
      post :create, key: {title: 'joes notebook', key: 'ssh-rsa aaa12345 joe@joes-notebook'}
      expect(assigns(:key)).to be_valid
      assert_equal 2, Key.all.size
      expect(flash[:notice]).to eq('SSH key was successfully added')
    end
    
    it 'should not add SSH key' do
      post :create, key: {title: 'joes notebook'}
      expect(assigns(:key)).not_to be_valid
      expect(flash[:alert]).to eq('Please enter title and key')
    end
    
    context "with JS format" do      
      it 'should add a new SSH key as JS' do
        post :create, {key: {title: 'joes notebook', key: 'ssh-rsa aaa12345 joe@joes-notebook'}, format: :js}
        expect(response.status).to eq(201)
      end
      
      it 'should add a new SSH key as JS' do
        post :create, {key: {title: 'joes notebook', key: ''}, format: :js}
        expect(response.status).to eq(422)
      end
    end
    
    context "with JSON format" do
      render_views
      let(:json) { JSON.parse(response.body) }
      
      it 'should add a new SSH key as JSON and return nothing' do
        post :create, {key: {title: 'joes notebook', key: 'ssh-rsa aaa12345 joe@joes-notebook'}, format: :json}
        expect(response.status).to eq(204)
      end
    end
  end
  
  describe '#destroy' do
    it 'should delete SSH key' do
      delete :destroy, { id: @key.id }
      assert_equal 0, Key.all.size
      expect(flash[:notice]).to eq('SSH key was successfully deleted')
    end
  end

end
