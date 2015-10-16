require 'rails_helper'

RSpec.describe Index, :type => :model do
  let(:location1) {FactoryGirl.create(:location)}
  let(:index1) { FactoryGirl.create(:index, location: location1) }
  let(:index2) { FactoryGirl.create(:index, index_cpu: index1.index_cpu + 10,
                                            index_iops: index1.index_iops + 10,
                                            index_bandwidth: index1.index_bandwidth + 10,
                                            location: location1) }
  let(:index3) { FactoryGirl.create(:index, index_cpu: index1.index_cpu,
                                            index_iops: index1.index_iops - 10,
                                            index_bandwidth: index1.index_bandwidth + 20,
                                            location: location1) }
  let(:indices_names) {%w(index_cpu index_iops index_bandwidth)}
  
  it "should instantiate object" do
    expect(index1).to be
  end
  
  context "for location" do
    it "should update max indices when creating index with bigger values" do
      indices_names.each {|name| expect(location1["max_" + name]).to eq 0}
      indices_names.each {|name| expect(index1.location["max_" + name]).to eq index1[name]}
      indices_names.each {|name| expect(index2.location["max_" + name]).to eq index2[name]}
      expect(index3.location.max_index_cpu).to eq index2.index_cpu
      expect(index3.location.max_index_iops).to eq index2.index_iops
      expect(index3.location.max_index_bandwidth).to eq index3.index_bandwidth
    end
  
    it "should not update  max indices when creating index with lower values" do
      indices_names.each {|name| expect(location1["max_" + name]).to eq 0}
      indices_names.each {|name| expect(index2.location["max_" + name]).to eq index2[name]}
      indices_names.each {|name| expect(index1.location["max_" + name]).to eq index2[name]}
    end
    
    context "restrict number of records" do
      let(:max_number) {Index::MAX_INDICES_PER_LOCATION}
      before(:each) do
        (max_number+3).times do |t|
          current = index1.dup
          current.created_at = index1.created_at - (t+1).days
          location1.indices << current
        end
      end
      
      it "should store most recent data points" do
        oldest = Index.where(location_id: location1.id).order(:created_at).first

        expect(Index.where(location_id: location1.id, created_at: oldest.created_at).first).to be
          
        expect {
          current = index1.dup
          current.created_at = index1.created_at + 1.day
          location1.indices << current
        }.not_to change{Index.where(location_id: location1.id).count}

        expect(Index.where(location_id: location1.id, created_at: oldest.created_at).first).to be_nil
      end
      
      it "should store MAX_INDICES_PER_LOCATION records" do
        expect(Index.where(location_id: location1.id).count).to eq max_number
      end
    end
  end
end
