class RemoveCouponCodes
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    Account.where.not(coupon_id: nil).each do |account|
      coupon = account.coupon

      if coupon.present? && Time.now > (account.coupon_activated_at + coupon.duration_months.months)
        account.update(coupon: nil)
      end
    end
  end
end
