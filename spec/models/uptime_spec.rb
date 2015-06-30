require 'rails_helper'

RSpec.describe Uptime, :type => :model do
  let(:uptime) { FactoryGirl.create(:uptime) }
  let(:new_uptime) {uptime.dup}
  it "should instantiate object with proper date type" do
    expect(uptime.starttime).to be_kind_of(ActiveSupport::TimeWithZone)
  end
  
  it "should instantiate object with correct date out of hash unix timestamp data" do
    expect(uptime.starttime).to eq(Time.at(1435014000))
  end
  
  it "should not update DB if the same record already exists" do
    expect(new_uptime.save_or_update).to be_falsy
    expect{new_uptime.save_or_update}.not_to change{Uptime.count}
  end
  
  it "should not create record if bad location_id" do
    new_uptime.starttime = uptime.starttime-1.day
    new_uptime.location_id = 5
    expect(new_uptime.save_or_update).to be_falsy
  end
  
  it "should not create record if no location_id" do
    new_uptime.starttime = uptime.starttime-1.day
    new_uptime.location_id = nil
    expect(new_uptime.save_or_update).to be_falsy
  end
  
  it "should update DB if new record with different starttime" do
    new_uptime.starttime = uptime.starttime-1.day
    expect{new_uptime.save_or_update}.to change{Uptime.count}.by(1)
  end
  
  it "should update DB if the record with same location_id and starttime differentiate" do
    new_uptime.uptime = 50000
    expect {
      expect(new_uptime.save_or_update).to be_truthy
    }.not_to change{Uptime.count}
    
    uptime.reload
    expect(uptime.uptime).to eq 50000
  end
  
  context "restrict number of records" do
    let(:max_number) {Uptime::MAX_DATA_PER_LOCATION}
    before(:each) do
      (max_number+3).times do |t|
        current = uptime.dup
        current.starttime = uptime.starttime - t.days
        current.save_or_update
      end
    end
    
    it "should store MAX_DATA_PER_LOCATION records" do
      expect(Uptime.count).to eq max_number
    end
    
    it "should store most recent data points" do
      oldest = Uptime.minimum(:starttime)
      expect {
        current = uptime.dup
        current.starttime = uptime.starttime + 1.day
        current.save_or_update
      }.not_to change{Uptime.count}
    
      expect(Uptime.find_by_starttime(oldest)).to be_nil
    end
    
    it "should remove all exceeding records in one 'save_or_update' call" do
      3.times do |t|
        current = uptime.dup
        current.starttime = uptime.starttime + (t+1).day
        current.save!
      end
      expect(Uptime.count).to eq max_number + 3
      
      new_uptime.starttime = uptime.starttime + 4.days
      new_uptime.save_or_update
      expect(Uptime.count).to eq max_number
    end
  end
end
