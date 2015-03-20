require 'rails_helper'

describe PublicController do
  describe '#user_message' do
    subject {post :user_message}
  
    it { is_expected.to be_success }
    xit { is_expected.to render 'dd'}
  
  end
end