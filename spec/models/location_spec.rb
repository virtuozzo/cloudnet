require 'rails_helper'

describe Location do
  let(:location) { FactoryGirl.create(:location) }

  it 'should be a valid location' do
    expect(location).to be_valid
  end

  it 'should be invalid without a provider' do
    location.provider = ''
    expect(location).not_to be_valid
  end

  describe 'Country and Country Codes' do
    it 'should be invalid without a country' do
      location.country = ''
      expect(location).not_to be_valid
    end

    it 'should be valid with a proper country code' do
      location.country = 'GB'
      expect(location).to be_valid
    end

    it 'should be invalid without a proper country code' do
      location.country = 'QU'
      expect(location).not_to be_valid
    end
  end

  it 'should be invalid without a city' do
    location.city = ''
    expect(location).not_to be_valid
  end
  
  it 'should be invalid without a hypervisor group id' do
    location.hv_group_id = nil
    expect(location).not_to be_valid
  end

  it 'should not be valid if the country is not a valid country code' do
    location.country = 'AA'
    expect(location).not_to be_valid
  end

  it 'should not be valid without some photo ids' do
    location.photo_ids = ''
    expect(location).not_to be_valid
  end
  
  describe 'forecasted revenue' do
    before :each do
      location.servers << FactoryGirl.build(:server, memory: 512)
      location.servers << FactoryGirl.build(:server, memory: 1024)
      location.send(:update_forecasted_revenue)
    end
    
    it 'updates servers forecasted revenue when price changed in location' do
      expect(location.servers.map(&:forecasted_rev)).to eq [35246400, 69652800]
      location.update_attribute(:price_memory, 50)
      expect(location.servers.map(&:forecasted_rev)).to eq [18043200, 35246400]
      location.update_attribute(:price_cpu, 20)
      expect(location.servers.map(&:forecasted_rev)).to eq [18023040, 35226240]
      location.update_attribute(:price_disk, 30)
      expect(location.servers.map(&:forecasted_rev)).to eq [17619840, 34823040]
    end
  end
end
