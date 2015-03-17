require 'rails_helper'

feature 'Dashboard' do
  context 'as a user not signed in' do
    scenario 'should redirect me to the sign in page' do
      visit dashboard_index_path
      expect(current_path).to eq(new_user_session_path)
    end
  end
  feature 'signed in user visits the index page' do
    before(:each) { authenticate_user }

    context 'pending user' do
      scenario 'should show the index page' do
        @user.update!(status: :pending)
        visit dashboard_index_path
       # expect(page).to have_content 'Pending'
        expect(page).to have_content 'Memory'
        expect(page).to have_content 'Disk Space'
        expect(page).to have_content 'CPU Cores'
      end
    end

    context 'suspended user' do
      scenario 'should show the suspended page' do
        @user.update!(status: :suspended)
        visit dashboard_index_path
        expect(page).to have_content 'Suspended'
      end
    end

    scenario 'should show the index page content' do
      visit dashboard_index_path
      expect(page).to have_content 'Memory'
      expect(page).to have_content 'Disk Space'
      expect(page).to have_content 'CPU Cores'
      expect(page).to have_content 'Bandwidth'
      expect(page).to have_content 'Tickets'
    end
  end
end
