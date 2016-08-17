class Coupon < ActiveRecord::Base
  has_many :accounts
  has_many :invoices
  has_many :credit_notes
  
  validates :coupon_code, :duration_months, :percentage, :expiry_date, presence: true
  validates :percentage, inclusion: 1..100
  validates :coupon_code, uniqueness: { case_sensitive: false }

  before_create :capitalize_coupon_code

  def self.find_coupon(code)
    return nil unless code.present?
    coupon = where(active: true).find_by(coupon_code: code.strip.upcase)
  end


  def not_expired?
    Date.today <= expiry_date
  end
  
  def percentage_decimal
    percentage / 100.0
  end

  def description
    "#{coupon_code} giving #{percentage}% off for #{duration_months} month(s)"
  end

  private

  def capitalize_coupon_code
    self.coupon_code = coupon_code.upcase
  end
end
