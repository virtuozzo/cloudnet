# Usages are used for displaying graphs
class ServerUsage < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :server, touch: true
  enum_field :usage_type, allowed_values: [:cpu, :network]
  validates :usage_type, :server, :usages, presence: true

  def self.cpu_usages(server, days_within = nil)
    ServerUsage.get_usages(server, :cpu, days_within)
  end

  def self.network_usages(server, days_within = nil)
    ServerUsage.get_usages(server, :network, days_within)
  end

  private

  def self.get_usages(server, type, days_within)
    return [] unless server.server_usages
    stats = server.server_usages.where(usage_type: type).limit(1).first
    if stats.present?
      usages = JSON.parse stats.usages
      if days_within.nil?
        return usages
      else
        recent_stats = usages.select {|u| Time.zone.parse(u["created_at"]).to_i > days_within.days.ago.to_i}
        return recent_stats
      end
    else
      return []
    end
  end
end
