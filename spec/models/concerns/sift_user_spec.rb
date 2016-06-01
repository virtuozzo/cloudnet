require 'rails_helper'

describe User::SiftUser do
  
  let!(:user) { FactoryGirl.create(:user) }
  
  it 'should get sift score' do
    user.sift_score
  end
  
  it 'should check sift label' do
    user.is_labelled_bad?
  end
  
  it 'should check sift actions' do
    user.sift_actions
  end
  
  it 'should check sift forumla' do
    user.sift_valid?
  end
  
  after :each do
    expect(@sift_client_double).to have_received(:perform).with(:create_event, "check_actions", anything, true)
  end
  
end
