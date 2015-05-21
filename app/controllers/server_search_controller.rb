class ServerSearchController < ApplicationController
  skip_before_action :authenticate_user!
  #before_action {redirect_to :root if user_signed_in?}
  layout "public"
  def index
    Analytics.track(current_user, event: 'Marketplace - online') if current_user
  end
  
  def create
    redirect_to :sign_in
  end
end
