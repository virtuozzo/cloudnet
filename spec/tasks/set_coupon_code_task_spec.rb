require 'rails_helper'

describe SetCouponCodeTask do
  
  let(:user) { FactoryGirl.create(:user) }
  let(:coupon) { FactoryGirl.create(:coupon) }
  subject { SetCouponCodeTask.new(user, coupon.coupon_code) }

  it 'sets the coupon' do
    expect(user.account.coupon).to be_nil
    subject.process
    expect(user.account.coupon).to eq coupon
  end
  
end
