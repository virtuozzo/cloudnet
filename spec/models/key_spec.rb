require 'rails_helper'

RSpec.describe Key, :type => :model do
  
  let (:key) { FactoryGirl.create(:key) }
  
  it 'should be valid' do
    expect(key).to be_valid
  end

  it 'should not be valid without title' do
    key.title = nil
    expect(key).not_to be_valid
  end

  it 'should not be valid without key' do
    key.key = nil
    expect(key).not_to be_valid
  end
  
end
