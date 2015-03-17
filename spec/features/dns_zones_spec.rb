require 'rails_helper'

feature 'DNS Zones' do
  context 'as a user not signed in' do
    scenario 'should redirect me to the sign in page' do
      visit dns_zones_path
      expect(current_path).to eq(new_user_session_path)
    end
  end
end
