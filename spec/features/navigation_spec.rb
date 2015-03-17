require 'rails_helper'

feature 'Navigation Bar' do
  feature 'user is not signed in' do
    scenario 'login page should have a sign in form' do
      visit new_user_session_path
      expect(page).to have_button 'Sign in'
    end
    
    scenario 'root page should have a choose server form' do
      visit root_path
      expect(page).to have_select 'cpu'
      expect(page).to have_select 'mem'
      expect(page).to have_select 'disc'
      expect(page).to have_button 'Search'
    end
  end

  feature 'user is signed in' do
    let (:nav) { page.find_by_id('menu') }

    before(:each) do
      authenticate_user
      visit root_path
    end

    scenario 'nav should have signed in user nav links' do
      expect(nav).to have_link 'Dashboard', href: dashboard_index_path
      expect(nav).to have_link 'Servers', href: servers_path
      # expect(nav).to have_link 'Billing', :href => servers_path
      expect(nav).to have_link 'DNS', href: dns_zones_path
      expect(nav).to have_link 'Support', href: tickets_path
    end

    scenario 'nav should not have an admin link' do
      expect(nav).to_not have_link 'Admin'
    end

    scenario "nav should tell me i'm signed in as" do
      expect(page).to have_content @user.full_name
    end

    scenario 'nav should have account links' do
      expect(page).to have_link 'Manage Account', href: edit_user_registration_path
      expect(page).to have_link 'Sign out', href: destroy_user_session_path
    end

    feature 'and is an admin' do
      before (:each) do
        @user.admin = true
        @user.save!
        visit root_path
      end

      scenario 'nav should have an admin link' do
        expect(nav).to have_link 'Admin'
      end
    end
  end
end
