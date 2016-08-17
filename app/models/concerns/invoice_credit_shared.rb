require 'active_support/concern'

module InvoiceCreditShared
  extend ActiveSupport::Concern

  def account=(account)
    super(account)
    self.tax_code   = account.tax_code
    self.vat_exempt = account.vat_exempt?
    self.vat_number = account.vat_number
    self.billing_address = account.billing_address if account.billing_address
    self.coupon_id  = account.coupon_id if account.coupon.present?
  end

  def hours_till_next_invoice
    Invoice.hours_till_next_invoice(account)
  end

  def pre_coupon_net_cost
    cost_from_items(:net_cost)
  end

  def pre_coupon_tax_cost
    cost_from_items(:tax_cost)
  end

  def pre_coupon_total_cost
    cost_from_items(:total_cost)
  end

  def net_cost
    cost_from_items(:net_cost) * (1 - coupon_percentage)
  end

  def tax_cost
    cost_from_items(:tax_cost) * (1 - coupon_percentage)
  end

  def total_cost
    cost_from_items(:total_cost) * (1 - coupon_percentage)
  end
  
  def trial_credits_total_cost
    cost_from_items(:total_cost, :trial_credits) * (1 - coupon_percentage)
  end
  
  def manual_credits_total_cost
    cost_from_items(:total_cost, :manual_credits) * (1 - coupon_percentage)
  end

  def pre_coupon_total_cost_cents
    Invoice.milli_to_cents(pre_coupon_total_cost)
  end

  def total_cost_cents
    Invoice.milli_to_cents(total_cost)
  end

  def tax_rate
    vat_exempt? ? 0.0 : Invoice::TAX_RATE
  end

  def billing_address=(address)
    write_attribute(:billing_address, address.to_json)
  end

  def billing_address
    address = read_attribute(:billing_address)

    if address.present?
      JSON.parse(address).deep_symbolize_keys
    else
      nil
    end
  end

  # Get the coupon associated with the current account
  def coupon
    if self.class == CreditNote && (manually_added? || trial_credit?)
      # Coupon does not apply to manually issued credit notes. Basically this removes it from the
      # credit note PDF.
      nil
    else
      super
    end
  end

  def coupon_percentage
    if coupon.present?
      coupon.percentage_decimal
    else
      0
    end
  end

  module ClassMethods
    def milli_to_cents(cost)
      (cost / Invoice::CENTS_IN_DOLLAR).round
    end

    def hours_till_next_invoice(account)
      return 0 unless account
      [account.hours_till_next_invoice, Account::HOURS_MAX].min
    end

    def in_gbp(total)
      total * Invoice::USD_GBP_RATE
    end

    def pretty_total(total, unit = '$', precision = 2)
      price = total / Invoice::MILLICENTS_IN_DOLLAR
      ActionController::Base.helpers.number_to_currency(price, unit: unit, precision: precision)
    end

    def with_tax(amount)
      amount * (1.0 + Invoice::TAX_RATE)
    end
  end
end
