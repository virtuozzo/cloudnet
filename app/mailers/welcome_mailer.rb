class WelcomeMailer < ActionMailer::Base
  default from: ENV['MAILER_DEFAULT_WELCOME']

  def welcome_email(user, token)
    @user = user
    @token = token
    mail(to: @user.email, subject: "Welcome to #{ENV['BRAND_NAME']}! Please confirm your account...")
  end
end
