class PublicController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :clear_remembered_path
  
  def main
    @regions = Region.active_regions
    analytics_info
  end
  
  def user_message
    Thread.new{EnquiryMailer.contact_page(params[:enquiry]).deliver_now}
  end
  
  private
  def clear_remembered_path
    session[:user_return_to] = nil
  end
  
  def analytics_info
    Analytics.track(current_user, event: 'Main Page')
  end
end
