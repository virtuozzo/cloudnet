require 'rails_helper'

describe UptimeTasks, :vcr do
  include_context :pingdom_env
  
  let(:tasks) {UptimeTasks.new}
  let(:all_servers_update) {tasks.perform(:update_all_servers)}
  let(:pingdom_servers) {tasks.perform(:pingdom_servers)}
  let (:pingdom_id) {1534749} #from vcr - Quadranet Miami
  let(:pingdom2_id) {1534660} #from vcr - Budget London Softlayer
  let(:pingom_not_connected) {1534715} #from vcr - HostPro - Kiev
  let!(:location) {FactoryGirl.create(:location, pingdom_id: pingdom_id)}
  let!(:location2) {FactoryGirl.create(:location, pingdom_id: pingdom2_id)}
  
  context "update_all_servers" do
    it 'should get all servers checks records' do
      allow(UptimeUpdateServers).to receive(:perform_async)
      expect(all_servers_update.count).to eq 34
    end
  end
  
  context "pingdom_servers" do 
    it "should get pingdom servers names" do
      expect(pingdom_servers).to be_an Array
      expect(pingdom_servers.count).to eq 34
      expect(pingdom_servers[0]).to eq ["Budget London Softlayer", "1534660:Budget London Softlayer"]
    end
  
    it "should return error message if connection not working" do
      allow(tasks).to receive(:checks)
      expect(pingdom_servers).to be_an Array
      expect(pingdom_servers.count).to eq 1
      expect(pingdom_servers[0]).to eq ["pingdom connection error", -1]
    end
  end
  
  context "update_servers" do
    before(:each) do
      allow(tasks).to receive(:performance_args).and_return(
        {
          includeuptime: true, 
          resolution: :day,
          from: 1433199600
        }
      )
    end
    it "should save performance data for given server (by pingdom check_id)" do

      expect {
        expect(tasks.perform(:update_servers, pingdom_id).count).to eq 1
      }.to change(location.uptimes, :count).by 30
    end
    
    it "should update all locations connected to given pingdom_id" do
      FactoryGirl.create(:location, pingdom_id: pingdom_id)
      expect {
        expect(tasks.perform(:update_servers, pingdom_id).count).to eq 2
      }.to change(Uptime, :count).by 60
      
    end
    
    it "should update existing data in db if changed in pingdom" do
      expect(tasks.perform(:update_servers, pingdom_id).count).to eq 1
      expect(tasks.perform(:update_servers, pingdom2_id).count).to eq 1
    end
    
    it "should not update data if same data read from pingdom" do 
      expect(tasks.perform(:update_servers, pingdom_id).count).to eq 1
      expect {
        expect(tasks.perform(:update_servers, pingdom_id).count).to eq 1
      }.not_to change(location.uptimes, :count)
    end
    
    it "should return false if none of locations is connected to pingdom_id" do
      expect {
        expect(tasks.perform(:update_servers, pingom_not_connected)).to be_falsey
      }.not_to change(Uptime, :count)
    end
  end
  
  context "update server" do
    it "should save performance data for given server (by location_id)" do
      allow(tasks).to receive(:performance_args).and_return(
        {
          includeuptime: true, 
          resolution: :day,
          from: 1433199600
        }
      )
      expect {
        expect(tasks.perform(:update_server, pingdom_id, location.id).count).to eq 30
      }.to change(location.uptimes, :count).by 30
    end
    
    it "should save performance data for given server for 100 days" do
      allow(tasks).to receive(:performance_args).and_return(
        {
          includeuptime: true, 
          resolution: :day,
          from: 1427155200
        }
      )
      expect {
        expect(tasks.perform(:update_server, pingdom_id, location.id, nil, 100).count).to eq 100
      }.to change(location.uptimes, :count).by 100
    end
    
    it "should return 0 updates if pingdom_id is nil" do
      expect(tasks.perform(:update_server, nil, location.id, nil, 100).count).to eq 0
    end
  end
end
