class RemoveCouponCodes
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    Account.where.not(coupon_id: nil).each do |account|
      if account.coupon.present? && Time.now > account.coupon_expires_at
        account.update(coupon: nil)
        account.user.update_forecasted_revenue
      end
    end
  end
end
