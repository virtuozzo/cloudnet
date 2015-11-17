class NegativeBalanceMailer < ActionMailer::Base
  default from: ENV['MAILER_NOTIFICATIONS_DEFAULT_FROM']

  def warning_email(user)
    @user = user
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: @user[:email],
      bcc: ENV['MAILER_ENQUIRY_RECIPIENTS'],
      subject: 'Cloud.net: negative balance warning'
    )
  end
  
  def shutdown_warning_email_to_user(user)
    Rails.logger.info "Shutdown warning email to #{user.email}"
    
    @user = user
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: user.email,
      subject: 'Cloud.net: negative balance - shutdown warning'
    )
  end
  
  def shutdown_action_email_to_user(user)
    Rails.logger.info "Shutdown action email to #{user.email}"
    
    @user = user
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: user.email,
      subject: 'Cloud.net: negative balance - all your servers shut down'
    )
  end
  
  def destroy_warning_email_to_user(user)
    Rails.logger.info "DESTROY! warning email to #{user.email}"
    
    @user = user
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: user.email,
      subject: 'Cloud.net: negative balance - DESTROY warning!'
    )
  end
end
