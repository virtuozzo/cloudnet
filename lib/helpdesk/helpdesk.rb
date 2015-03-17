class Helpdesk
  def self.new
    klass.new
  end

  class Methods
    def new_ticket(_id, _details)
      # In the details hash, the following params are set
      # subject, body, user, department, server
      fail NotImplementedError
    end

    def get_ticket(_ref)
    end

    def reply_ticket(_ref, _body, _user)
      fail NotImplementedError
    end

    def close_ticket(_ref)
      fail NotImplementedError
    end

    def self.departments
      fail NotImplementedError
    end

    def self.config
      fail NotImplementedError
    end
  end

  def self.method_missing(method_name, *_args, &_block)
    klass.send(method_name)
  end

  private

  def self.klass
    Zendesk
  end
end
