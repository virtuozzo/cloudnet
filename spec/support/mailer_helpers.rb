module MailerHelpers

  def send_mail(method, *arguments)
    @_mail_called = true
    @_mailer_method = method
    @_mailer_arguments = arguments
  end

  def mailer
    raise "You must use mail(:method_name) before calling :mailer" unless @_mail_called
    @mailer ||= described_class.send :new, @_mailer_method, *@_mailer_arguments
  end

  def headers
    raise "You must use mail(:method_name) before calling :response" unless @_mail_called
    @headers ||= mailer.headers
  end
  
  def response
    raise "You must use mail(:method_name) before calling :response" unless @_mail_called
    @response ||= mailer.response_body
  end

  def assigns(method)
    raise "You must use mail(:method_name) before calling :assigns" unless @_mail_called
    mailer.view_assigns.with_indifferent_access[method]
  end

end

RSpec.configure do |config|
  config.include MailerHelpers, type: :mailer
end