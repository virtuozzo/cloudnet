class RegistrationsController < Devise::RegistrationsController
  layout "public"
  # def new
  # end
  #
  # def create
  #   flash[:info] = 'Registrations are not open yet for the Cloud.net beta, but please check back soon'
  #   redirect_to :back
  # end

  def new
    # We want to have the ability to fill in some params
    prepare_order if session[:user_return_to]
    build_resource(sign_up_params)
    respond_with resource
  end

  protected

  def after_inactive_sign_up_path_for(resource)
    session[:registration_flash] = flash[:notice] if flash[:notice]
    super
  end
  
  private
  
  def prepare_order
    @server_params =  Rack::Utils.parse_nested_query(
                         URI::parse(session[:user_return_to]).query).symbolize_keys
    @location = Location.find(@server_params[:id])
    set_price
  end
  
  def set_price
    @h_price = @location.hourly_price( @server_params[:mem].to_i,
                                     @server_params[:cpu].to_i,
                                     @server_params[:disk].to_i).to_f
    @m_price = (@h_price * 672 / 1000).round.to_f / 100
    @h_price = @h_price.round.to_f / 100000
  end
end
