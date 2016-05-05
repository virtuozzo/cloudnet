class RemoveCouponCodes
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    Account.where.not(coupon_id: nil).each do |account|
      coupon = account.coupon

      if coupon.present? && Time.now > (account.coupon_activated_at + coupon.duration_months.months)
        account.update(coupon: nil)
        account.user.update_forecasted_revenue
      end
    end
  end
end
