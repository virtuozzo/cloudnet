require 'rails_helper'

describe DashboardController do
  describe 'as a signed in user who is active' do
    before(:each) { sign_in_onapp_user }

    describe 'going to the index page' do
      it 'should render the dashboard index page' do
        get :index
        expect(response).to be_success
        expect(response).to render_template('dashboard/index')
      end
    end
  end
end
