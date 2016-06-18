require 'rails_helper'

RSpec.describe ApiKey, type: :model do
  
  let (:api_key) { FactoryGirl.create(:api_key) }
  
  it 'should be valid' do
    expect(api_key).to be_valid
  end

  it 'should not be valid without title' do
    api_key.title = nil
    expect(api_key).not_to be_valid
  end
  
  it 'should not allow to create api key with the same key twice' do 
    expect(api_key.save).to be_truthy
    api_key_with_the_same_key = api_key.dup
    expect(api_key_with_the_same_key).not_to be_valid
  end
  
  it 'should not allow a user to create more than 3 api keys' do
    user = FactoryGirl.create(:user_onapp)
    FactoryGirl.create_list(:api_key, 3, user: user)
    new_api_key = FactoryGirl.build(:api_key, user: user)
    expect(new_api_key).not_to be_valid
  end
  
end
