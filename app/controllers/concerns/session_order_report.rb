module SessionOrderReport
  private
  
  def prepare_order
    return unless session[:user_return_to]
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
