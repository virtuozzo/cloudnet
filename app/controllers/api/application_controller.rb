class Api::ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :authenticate_user!
  
  def status
    render :text => "OK"
  end

  def environment
    render :json => '"' + Rails.env.to_s + '"'
  end
  
end