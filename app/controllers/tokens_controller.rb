class TokensController < DeviseOtp::TokensController
  skip_before_filter :ensure_credentials_refresh, only: [:enable_otp]

  def enable_otp
    resource.update(otp_challenge_expires: expire_when)

    token = params[resource_name][:token]
    if !resource.otp_enabled? && resource.validate_otp_token(token, false)
      resource.enable_otp!
      otp_set_flash_message :success, :successfully_enabled
    else
      otp_set_flash_message :error, :not_enabled
    end

    redirect_to user_otp_token_path
  end

  def disable_otp
    resource.disable_otp! if resource.otp_enabled?
    otp_set_flash_message :success, :successfully_disabled
    redirect_to user_otp_token_path
  end

  def recovery_codes
    redirect_to edit_user_registration_path unless resource.otp_enabled?

    @tokens = resource.next_otp_recovery_tokens.values

    respond_to do |format|
      format.any do
        filename = "#{current_user.email}_recovery_codes_#{Time.now}.txt"
        data = render_to_string template: 'devise_otp/tokens/recovery.txt'
        send_data data, filename: filename
      end
    end
  end

  def reset_tokens
    if resource.reset_otp_credentials!
      otp_set_flash_message :success, :successfully_reset_creds
    end

    redirect_to user_otp_token_path
  end

  private

  def expire_when
    Time.now + resource.class.otp_credentials_refresh
  end
end
