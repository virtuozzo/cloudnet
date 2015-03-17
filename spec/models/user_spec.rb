require 'rails_helper'

describe User do
  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }

  it 'has a valid factory' do
    expect(user).to be_valid
  end

  it 'is invalid without a full name' do
    user.full_name = ''
    expect(user).not_to be_valid
  end

  it 'contains a full name' do
    expect(user.full_name).not_to be_empty
  end

  it 'should not be an admin by default' do
    expect(user.admin).to be false
    expect(admin.admin).to be true
  end

  describe 'status' do
    it 'should have a pending status by default' do
      expect(user.status_pending?).to be true
    end

    it 'should push a job to the queue to create a user' do
      expect { user.save! }.to change(CreateOnappUser.jobs, :size).by(1)
    end
  end

  it 'should create an account when you create a user' do
    expect(user.account).not_to be_nil
  end
end
