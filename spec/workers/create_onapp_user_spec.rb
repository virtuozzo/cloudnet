require 'rails_helper'

describe CreateOnappUser do
  let(:user) { FactoryGirl.create(:user) }

  it 'should attempt to create a user' do
    user_tasks = double('UserTasks')
    allow(UserTasks).to receive(:new).and_return(user_tasks)
    allow(user_tasks).to receive(:perform).and_return(true)

    CreateOnappUser.new.perform(user.id)
    expect(user_tasks).to have_received(:perform).with(:create, user.id)
  end
end
