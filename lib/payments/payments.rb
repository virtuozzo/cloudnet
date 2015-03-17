class Payments
  def self.new
    klass.new
  end

  class Methods
    def create_customer(_user)
      fail NotImplementedError
    end

    def add_card(_cust_token, _card_token)
      fail NotImplementedError
    end
  end

  def self.method_missing(method_name, *_args, &_block)
    klass.send(method_name)
  end

  private

  def self.klass
    StripePayments
  end
end
