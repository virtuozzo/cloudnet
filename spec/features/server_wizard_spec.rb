require 'rails_helper'

feature 'Server Wizard' do
  context 'as a user not signed in' do
    scenario 'should show me the server options page page' do
      visit servers_create_path
      expect(current_path).to eq(servers_create_path)
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
