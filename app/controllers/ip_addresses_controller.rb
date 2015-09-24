class IpAddressesController < ApplicationController
  before_action :set_server
  before_action :set_ip_address, except: [:index, :create]
  before_action :check_multiple_ip_support, except: [:index]
  
  def index
    respond_to do |format|
      format.html { 
        check_multiple_ip_support
        @ip_address = @server.server_ip_addresses.new 
      }
      format.json { @ip_addresses = @server.server_ip_addresses.order(primary: :desc, id: :asc) }
    end
  end
  
  def create
    if @server.can_add_ips?
      AssignIpAddress.perform_async(current_user.id, @server.id)
      Rails.cache.write([Server::IP_ADDRESSES_COUNT_CACHE, @server.id], @server.server_ip_addresses.count + 1)
      redirect_to server_ip_addresses_path(@server), notice: 'IP address has been requested and will be added shortly'
      return
    else
      redirect_to server_ip_addresses_path(@server), alert: 'You cannot add anymore IP addresses to this server.'
    end
  rescue Exception => e
    ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'IpAddresses#Create' })
    flash.now[:alert] = 'Could not create IP address. Please try again later'
    redirect_to server_ip_addresses_path(@server)
  end
  
  def destroy
    raise "Cannot remove Primary IP address" if @ip_address.primary?
    IpAddressTasks.new.perform(:remove_ip, current_user.id, @server.id, @ip_address.identifier)
    @ip_address.destroy!
    Rails.cache.write([Server::IP_ADDRESSES_COUNT_CACHE, @server.id], @server.server_ip_addresses.count)
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
  
  def check_multiple_ip_support
    redirect_to_dashboard unless @server.supports_multiple_ips?
  end
end
