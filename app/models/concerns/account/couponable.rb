require 'active_support/concern'

class Account < ActiveRecord::Base
  module Account::Couponable
    extend ActiveSupport::Concern

    def coupon
      Coupon.find_by_id(coupon_id)
    end

    def coupon=(coupon)
      if coupon.present?
        update(coupon_id: coupon.id, coupon_activated_at: Time.now)
      else
        update(coupon_id: nil)
      end
    end

    def can_set_coupon_code?
      if coupon_activated_at.present? && Time.now < (coupon_activated_at + COUPON_LIMIT_MONTHS)
        return false
      else
        return true
      end
    end

    def set_coupon_code(code)
      coupon = Coupon.find_coupon(code)
      if coupon.present? && coupon.not_expired?
        self.coupon = coupon
        user.update_forecasted_revenue
        return true
      end
      false
    end
  end
end
