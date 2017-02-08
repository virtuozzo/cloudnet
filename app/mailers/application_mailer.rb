class ApplicationMailer < ActionMailer::Base
  default from: ENV['MAILER_DEFAULT_WELCOME']
  layout 'mailer'
end
