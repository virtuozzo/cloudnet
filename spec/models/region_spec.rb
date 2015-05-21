require 'rails_helper'

RSpec.describe Region, :type => :model do
  let (:region) { FactoryGirl.create(:region) }

  it 'should be a valid location' do
    expect(region).to be_valid
  end
  
  it 'should be invalid without a name' do
    region.name = ''
    expect(region).not_to be_valid
  end
  
  it 'should not allow to create region with the same name twice' do 
    expect(region.save).to be_truthy
    region_with_the_same_name = region.dup
    expect(region_with_the_same_name).not_to be_valid
  end
end