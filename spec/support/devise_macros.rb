require 'rails_helper'

module ControllerHelpers
  def sign_in_onapp_user
    @request.env["devise.mapping"] = Devise.mappings[:user]
    user = FactoryGirl.create(:user_onapp)
    user.confirm
    sign_in user
    @current_user = user
  end
end

module AuthHelpers
  def authenticate_user
    @user = FactoryGirl.create(:user_onapp)
    @user.confirm

    visit new_user_session_path
    fill_in 'Email Address', with: @user.email
    fill_in 'Password', with: @user.password
    click_button 'Sign in'
  end
end

RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
  config.include Warden::Test::Helpers

  config.before(:each) { Warden.test_mode! }
  config.after(:each) { Warden.test_reset! }

  config.include ControllerHelpers, type: :controller
  config.include AuthHelpers
end
