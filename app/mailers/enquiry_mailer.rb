class EnquiryMailer < ActionMailer::Base
  RECIPIENTS = ENV['MAILER_ENQUIRY_RECIPIENTS'].split(',')
  default to: RECIPIENTS

  def contact_page(e)
    Rails.logger.info "Enquiry email from contact page from #{e[:email]}"
    @name, @phone, @msg = e[:name], e[:phone], e[:msg]
    subject = 'Enquiry from contact page'

    mail subject: subject, from: e[:email]
  end
end
