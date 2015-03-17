class SetCouponCodeTask < BaseTask
  def initialize(user, code)
    @user = user
    @coupon_code = code
  end

  def process
    account = @user.account

    unless account.can_set_coupon_code?
      errors << 'You can only use one coupon code per six month period'
      return false
    end

    unless account.set_coupon_code(@coupon_code)
      errors << 'Coupon code is not valid'
      return false
    end

    true
  end
end
