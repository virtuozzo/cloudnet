require 'rails_helper'

RSpec.describe BackupsController, :type => :controller do
  
  render_views
  
  let(:json) { JSON.parse(response.body) }
  
  describe 'on a server with manual backup support' do
    before(:each) { 
      sign_in_onapp_user
      @server = FactoryGirl.create(:server, user: @current_user)
      @server.update(state: :on)
      @server_backup = FactoryGirl.create(:server_backup, server: @server)
    }
    
    describe '#index' do
      it 'should render the servers backups list' do
        get :index, { server_id: @server.id }
        expect(response).to be_success
        expect(response).to render_template('backups/index')
      end
      
      it 'should get list of backups as JSON' do
        get :index, { server_id: @server.id, format: :json }
        expect(json.collect{|backup| backup["identifier"]}).to include(@server_backup.identifier)
      end
    end
      
    describe '#create' do
      it 'should add a new backup' do
        allow(CreateBackup).to receive(:perform_async).and_return(true)
        post :create, { server_id: @server.id }
        expect(CreateBackup).to have_received(:perform_async)
        expect(response).to redirect_to(server_backups_path(@server))
        expect(flash[:notice]).to eq('Backup has been requested and will be created shortly')
        expect(Rails.cache.read([Server::BACKUP_CREATED_CACHE, @server.id])).to eq(true)
      end
    end
    
    describe '#restore' do
      it 'should restore a backup' do
        @backup_tasks = double('BackupTasks', perform: true)
        allow(BackupTasks).to receive(:new).and_return(@backup_tasks)
        post :restore, { server_id: @server.id, id: @server_backup.id }

        expect(@backup_tasks).to have_received(:perform)
        expect(response).to redirect_to(server_path(@server))
        expect(flash[:notice]).to eq('Backup restore will occur shortly')
      end
    end
    
    describe '#destroy' do
      it 'should remove backup' do
        @backup_tasks = double('BackupTasks', perform: true)
        allow(BackupTasks).to receive(:new).and_return(@backup_tasks)
        delete :destroy, { server_id: @server.id, id: @server_backup.id }

        expect(@backup_tasks).to have_received(:perform)
        expect(response).to redirect_to(server_backups_path(@server))
        expect(flash[:notice]).to eq('Backup has been deleted')
      end
    end
    
  end
  
  describe 'on a server without manual backup support' do
    before(:each) { 
      sign_in_onapp_user
      @server = FactoryGirl.create(:server, user: @current_user)
      @server.location.update(hv_group_version: '3.0.0')
    }
    
    describe 'going to the index page' do
      it 'should redirect to dashboard' do
        get :index, { server_id: @server.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

end
