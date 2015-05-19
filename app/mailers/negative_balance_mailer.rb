# Email a user when then have negative balance. We will need to remove their servers if they're
# not paying for them
class NegativeBalanceMailer < ActionMailer::Base
  default from: ENV['MAILER_NOTIFICATIONS_DEFAULT_FROM']

  def warning_email(user)
    @user = user
    # NB. remaining_balance() represents negative balance with positive values
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: @user[:email],
      bcc: ENV['MAILER_ENQUIRY_RECIPIENTS'],
      subject: 'Cloud.net: negative balance warning'
    )
  end
end
