class CredentialsController < DeviseOtp::CredentialsController
  private

  def done_valid_refresh
    pp 'Done valid refresh!'
    otp_refresh_credentials_for(resource)
    otp_set_flash_message :success, :valid_refresh if is_navigational_format?
    redirect_to otp_fetch_refresh_return_url
  end
end
