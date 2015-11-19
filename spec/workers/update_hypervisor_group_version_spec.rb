require 'rails_helper'

describe UpdateHypervisorGroupVersion do
 
  it 'should update HV group version for each location' do
    VCR.use_cassette('UpdateHypervisorGroupVersion/list_hypervisor_zones') do
      location = FactoryGirl.create(:location)
      location.update_attribute(:hv_group_version, '4.0.0')
    
      UpdateHypervisorGroupVersion.new.perform
      location.reload
      expect(location.hv_group_version).to eq('4.1.0')
    end
  end
  
  it 'should update HV group version for locations with same HV group ID' do
    VCR.use_cassette('UpdateHypervisorGroupVersion/list_hypervisor_zones') do
      location1 = FactoryGirl.create(:location)
      location1.update_attribute(:hv_group_version, '4.0.0')
    
      location2 = FactoryGirl.create(:location)
      location2.update_attribute(:hv_group_version, '4.0.0')
    
      UpdateHypervisorGroupVersion.new.perform
    
      location1.reload
      location2.reload
    
      expect(location1.hv_group_version).to eq('4.1.0')
      expect(location2.hv_group_version).to eq('4.1.0')
    end
  end
 
end