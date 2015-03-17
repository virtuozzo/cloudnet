# This patch is used for Devise OTP Gem. It's needed because
# Devise OTP does not determine whether a request is a GET
# request to determine whether it can re-do the request
# on re-auth using the password and auth code

# Basically don't try to replay non-GET requests

require DeviseOtpAuthenticatable::Engine.root.join('app/controllers/devise_otp/credentials_controller')

module DeviseOtp
  class CredentialsController < DeviseController
    private

    alias_method :done_valid_refresh_get_post, :done_valid_refresh

    def done_valid_refresh
      otp_refresh_credentials_for(resource)

      begin
        url = otp_fetch_refresh_return_url
        ActionController::Routing::Routes.recognize_path(url, method: :get)
        otp_set_flash_message :success, :valid_refresh if is_navigational_format?
        respond_with resource, location: url
      rescue
        otp_set_flash_message :success, :valid_refresh_try_again if is_navigational_format?
        respond_with resource, location: otp_token_path_for(resource)
      end
    end
  end
end
