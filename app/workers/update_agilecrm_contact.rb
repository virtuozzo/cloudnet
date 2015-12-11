class UpdateAgilecrmContact
  include Sidekiq::Worker

  def perform(user_id, old_email = nil)
    user = User.find user_id
    first_name = user.full_name.split(' ').first
    last_name = user.full_name.split(' ').last
    params = { first_name: first_name, last_name: last_name, email: user.email, CloudnetID: user.id, StripeID: user.account.gateway_id, EmailVerified: !user.confirmed_at.nil? }
    email = old_email || user.email
    contact = AgileCRMWrapper::Contact.search_by_email(email)
    if contact.nil?
      AgileCRMWrapper::Contact.create(params)
    else
      contact.update(params)
    end
  end
end
