require 'rails_helper'

describe UpdateHypervisorGroupVersion do
 
  it 'should update HV group version for each location', :vcr do
    location = FactoryGirl.create(:location)
    location.update_attribute(:hv_group_version, '4.0.0')
    
    UpdateHypervisorGroupVersion.new.perform
    location.reload
    expect(location.hv_group_version).to eq('4.1.0')
  end
 
end