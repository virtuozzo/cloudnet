# Usages are used for displaying graphs
class ServerUsage < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :server, touch: true
  enum_field :usage_type, allowed_values: [:cpu, :network]
  validates :usage_type, :server, :usages, presence: true

  def self.cpu_usages(server)
    ServerUsage.get_usages(server, :cpu)
  end

  def self.network_usages(server)
    ServerUsage.get_usages(server, :network)
  end

  private

  def self.get_usages(server, type)
    return [] unless server.server_usages
    stats = server.server_usages.where(usage_type: type).limit(1).first
    if stats.present?
      return JSON.parse stats.usages
    else
      return []
    end
  end
end
