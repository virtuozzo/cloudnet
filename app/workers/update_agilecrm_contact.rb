class UpdateAgilecrmContact
  include Sidekiq::Worker

  def perform(user_id, old_email = nil, tags = [])
    return if ENV['AGILECRM_API_KEY'].blank?
    user = User.find user_id
    return if user.suspended
    first_name = user.full_name.split(' ').first
    last_name = user.full_name.split(' ').last
    email_verified = !user.confirmed_at.nil? ? 'on' : 'off'
    params = {
      first_name: first_name,
      last_name: last_name,
      email: user.email,
      CloudnetID: user.id,
      StripeID: user.account.gateway_id,
      EmailVerified: email_verified,
      company: user.account.company_name,
      created: user.created_at,
      SignIn: user.current_sign_in_at,
      tags: tags
    }
    email = old_email || user.email
    contact = AgileCRMWrapper::Contact.search_by_email(CGI.escape(email))
    if contact.nil?
      AgileCRMWrapper::Contact.create(params)
    else
      contact.update(params)
    end
  end
end
