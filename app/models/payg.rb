class Payg
  VALID_TOP_UP_AMOUNTS = [10, 25, 50, 100, 500, 1000]
  MIN_AUTO_TOP_UP_AMOUNT = 25
  CENTS_IN_DOLLAR = 100

  # This is used in the summary section of a PAYG invoice. Over a month a server may be billed
  # at different rates, depending on an associated coupon or the resource sizes.
  def self.categorize_transactions(transactions)
    categories = {}

    transactions.each do |transaction|
      key = make_key([transaction.net_cost, transaction.coupon_id])
      if categories.key?(key)
        categories[key][:hours] += 1
      else
        categories[key] = {
          hours:    1,
          coupon:   transaction.coupon,
          net_cost: transaction.net_cost,
          cost:     transaction.cost
        }
      end
    end

    categories
  end

  private

  def self.make_key(elements)
    ('trans_' + elements.join('_')).to_sym
  end
end
