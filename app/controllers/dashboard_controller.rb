class DashboardController < ApplicationController
  def index
    stats
    costs
  end

  private

  def stats
    @stats = DashboardStats.gather_stats(current_user)
  end

  def costs
    @costs = DashboardStats.gather_costs(current_user)
  end
end
