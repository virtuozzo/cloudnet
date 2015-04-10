class Location < ActiveRecord::Base
  include CloudIndexCalculationTemplate

  has_many :templates
  has_many :servers
  has_many :packages
  has_many :indices, dependent: :destroy

  acts_as_paranoid

  validates :provider, :country, :city, :hv_group_id, :photo_ids, presence: true
  validates :price_memory, :price_disk, :price_cpu, numericality: true
  validates :max_index_cpu, :max_index_iops, :max_index_bandwidth, :max_index_uptime, numericality: true
  validate :verify_valid_country_code

  def country_name
    Rails.cache.fetch([self, :country_name]) do
      IsoCountryCodes.find(country).name
    end
  end

  def to_s
    "#{country_name} (#{country}), #{city}, #{provider}"
  end

  def hourly_price(memory, cpu, disk)
    (memory * price_memory) + (cpu * price_cpu) + (disk * price_disk)
  end

  private

  def verify_valid_country_code
    errors.add(:country, 'Invalid Country') unless country && IsoCountryCodes.all.detect { |c| c.alpha2.downcase == country.downcase }
  end

  def indices_for_calculation
    @indices_for_calculation ||= indices.order(:created_at).last
  end

  def calc_indices_update
    ["for_location", Rails.cache.read([Index::CURRENT_INDICES_CACHE, id])]
  end
end
