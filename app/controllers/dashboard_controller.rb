class DashboardController < ApplicationController
  
  helper_method :cache_key_for_dashboard
  
  def index
    @servers = current_user.servers.includes(:location).order(id: :asc)
    @cache_key_params = cache_key_params
    @stats = stats
    @costs = costs
  end
  
  private
  
  def stats
    Rails.cache.fetch(cache_key_for_dashboard('stats'), expires_in: 12.hours) do
      DashboardStats.gather_stats(current_user, @servers)
    end
  end
  
  def costs
    Rails.cache.fetch(cache_key_for_dashboard('costs'), expires_in: 12.hours) do
      DashboardStats.gather_costs(current_user, @servers)
    end
  end
  
  def cache_key_for_dashboard(key)
    "#{key}/" + @cache_key_params
  end
  
  def cache_key_params
    server_count = @servers.size
    server_max_updated_at = current_user.servers.maximum(:updated_at).try(:utc).try(:to_s, :number)
    ticket_max_updated_at = current_user.tickets.maximum(:updated_at).try(:utc).try(:to_s, :number)
    server_usages_updated_at = ServerUsage.where("usage_type = 'cpu' AND server_id IN (?)", @servers.map(&:id)).maximum(:updated_at).try(:utc).try(:to_s, :number)
    "#{current_user.id}/servers/all-#{server_count}-#{server_max_updated_at}/server_usages/#{server_usages_updated_at}/tickets/#{ticket_max_updated_at}"
  end
  
end
