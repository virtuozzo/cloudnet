require 'rails_helper'

describe ServerSearchController do
  describe '#index' do
    subject {get :index}
  
    context 'when not logged in' do
      it { is_expected.to be_success }
      it { is_expected.to render_template :public }
    end
  
    context 'when logged in' do
      before(:each) {sign_in_onapp_user}
      it {is_expected.to redirect_to :root}
    end 
  end
end