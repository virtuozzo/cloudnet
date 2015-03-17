class ErrorLogging
  def self.new
    klass.new
  end

  class Methods
    def track_exception(_e, _params)
      fail NotImplementedError
    end
  end

  def self.method_missing(method_name, *_args, &_block)
    klass.send(method_name)
  end

  private

  def self.klass
    SentryLogging
  end
end
