require 'rails_helper'

describe UserTasks, :vcr do
  include_context :with_user

  it 'creates a user in OnApp and updates our user' do
    expect(@user.onapp_user).to eq 'auto_rspec_user'
    expect(@user.onapp_email).to eq 'auto_rspec_user@onapp.com'
  end
end
