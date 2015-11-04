require 'rails_helper'

describe LocationIndices, :vcr do
  let(:location) {FactoryGirl.create(:location, hv_group_id: 7)}
  
  it "should read Indices for location" do 
    expect(LocationIndices.new(location).process).to be_an Array
  end
  
  it "should return nil if no hv_group_id" do
    location.hv_group_id = nil
    expect(LocationIndices.new(location).process).to be_nil
  end
  
  #TODO: Enable error raising when all locations have performance tests enabled
  xit "should raise error if no resource available" do
    location.hv_group_id = 555
    expect{LocationIndices.new(location).process}.to raise_error(Faraday::ResourceNotFound)
  end
  
  it "should return Indices in creation date order" do
    indices = LocationIndices.new(location).process
    indices.inject(0) do |m, i|
      timestamp = i[:created_at].to_time.to_i
      expect(timestamp).to be > m
      m = timestamp
    end
  end
end