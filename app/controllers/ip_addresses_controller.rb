class IpAddressesController < ApplicationController
  before_action :set_server
  before_action :set_ip_address, except: [:index, :create]
  
  def index
    @ip_address = @server.server_ip_addresses.new
    @ip_addresses = @server.server_ip_addresses.order(primary: :desc, id: :asc)
    respond_to do |format|
      format.html { @ip_addresses = @ip_addresses.page(params[:page]).per(10) }
      format.json
    end
  end
  
  def create
    AssignIpAddress.perform_async(current_user.id, @server.id)
    redirect_to server_ip_addresses_path(@server), notice: 'IP address has been requested and will be created shortly'
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'IpAddresses#Create' })
    flash.now[:alert] = 'Could not create IP address. Please try again later'
    redirect_to server_ip_addresses_path(@server)
  end
  
  def destroy
    IpAddressTasks.new.perform(:remove_ip, current_user.id, @server.id, @ip_address.identifier)
    @ip_address.destroy!
    redirect_to server_ip_addresses_path(@server), notice: 'IP address has been removed'
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'IpAddresses#Destroy' })
    flash.now[:alert] = 'Could not remove IP address. Please try again later'
    redirect_to server_ip_addresses_path(@server)
  end
  
  private

  def set_server
    @server = current_user.servers.find(params[:server_id])
  end
  
  def set_ip_address
    @ip_address = @server.server_ip_addresses.find(params[:id])
  end
end
