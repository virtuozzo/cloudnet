class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!
  before_action :check_user_status, unless: :controller_allowed?
  before_action :set_session_id
  
  helper_method :is_admin_user?
  helper_method :logged_in_as?

  def is_admin_user?
    current_user && current_user.admin?
  end

  def logged_in_as?
    session[:admin_id].present?
  end

  def real_admin_id
    return session[:admin_id] if logged_in_as?
    nil
  end

  def ip
    request.remote_ip
  end

  def development?
    Rails.env.development?
  end

  def redirect_to_dashboard
    redirect_to root_path
  end

  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :full_name
    devise_parameter_sanitizer.for(:account_update) << :full_name
  end

  def format_error_messages(messages)
    error_json = messages

    if error_json.is_a?(String)
      begin
        error_json = JSON.parse(messages)
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'Application#FormatErrorMessages' })
        return 'An error occured. Could not complete action'
      end
    end

    if error_json.key? 'errors' && error_json['errors'].is_a?(Hash)
      errors = error_json['errors'].map do |k, v|
        errors << "#{k.capitalize} #{v.join(', ')}"
      end
      errors.join(', ')
    elsif error_json.key? 'errors' && error_json['errors'].is_a?(Array)
      error_json['errors'].join(', ')
    else
      'An error occured. Could not complete action'
    end
  end

  private

  def controller_allowed?
    controllers = %w(tickets ticket_replies public server_search)
    devise_controller? || controllers.include?(params[:controller])
  end

  def check_user_status
    if current_user.status_suspended?
      render 'app/suspended'
    end
  end
  
  def anonymous_id
    session.id
  end

  def set_session_id
    logger.info "INFO: #{request.user_agent}"
    Thread.current[:session_id] = anonymous_id
  end
  
end
