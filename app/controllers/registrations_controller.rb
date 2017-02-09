class RegistrationsController < Devise::RegistrationsController
  include SessionOrderReport
  before_action :prepare_order
  before_action :load_keys, only: [:edit, :update]

  def new
    analytics_info unless monitoring_service?
    build_resource(sign_up_params)
    respond_with resource
  end
  
  def edit
    @key = Key.new
    super
  end
  
  def update
    super
    current_user.reload
    current_user.update_sift_account
  end

  protected

  def after_inactive_sign_up_path_for(resource)
    session[:registration_flash] = flash[:notice] if flash[:notice]
    super
  end
  
  def analytics_info
    Analytics.track(current_user, event_details, anonymous_id, request)
  end
  
  def event_details
    {event: 'Registration Page',
      properties: UtmTracker.extract_properties(params)
    }
  end
  
  private
  
  def load_keys
    @keys = current_user.keys
    @api_keys = current_user.api_keys
  end
end
