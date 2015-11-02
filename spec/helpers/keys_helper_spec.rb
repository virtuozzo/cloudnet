require 'rails_helper'

RSpec.describe KeysHelper, :type => :helper do
  
  describe "SSH fingerprint" do
    it "returns the fingerprint of SSH key" do
      @user = FactoryGirl.create(:user_onapp)
      @key = FactoryGirl.create(:key, user: @user)
      expect(helper.fingerprint(@key.key)).to eq("9c:25:15:d7:b1:43:7d:a6:27:3d:8b:bb:f7:32:da:ea")
    end
  end
  
end
