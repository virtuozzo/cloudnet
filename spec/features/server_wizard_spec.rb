require 'rails_helper'

feature 'Server Wizard' do
  context 'as a user not signed in' do
    scenario 'should redirect me to the sign up page' do
      visit servers_create_path
      expect(current_path).to eq(new_user_registration_path)
    end
  end
  feature 'Step 1' do
    before(:each) { authenticate_user }
    xit 'should have location sections' do
      visit servers_create_path
      expect(page).to have_content 'Select Location'
    end
  end
end
