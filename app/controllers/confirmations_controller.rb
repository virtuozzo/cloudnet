# Overriding Devise's Confirmation controller so that we can update Sift Science with updated user details
class ConfirmationsController < Devise::ConfirmationsController

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    old_email = current_email
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      resource.update_sift_account
      set_flash_message(:notice, :confirmed) if is_flashing_format?
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
    end
  end

  private

  def current_email
    confirmable = resource_class.find_first_by_auth_conditions(confirmation_token: params[:confirmation_token])
    unless confirmable
      confirmation_digest = Devise.token_generator.digest(resource_class, :confirmation_token, params[:confirmation_token])
      confirmable = resource_class.find_or_initialize_with_error_by(:confirmation_token, confirmation_digest)
    end
    confirmable.email
  rescue
    nil
  end

end
