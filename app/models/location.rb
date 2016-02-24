class Location < ActiveRecord::Base
  include CloudIndexCalculationTemplate

  has_many :templates
  has_many :servers
  has_many :packages
  has_many :indices, dependent: :destroy
  has_many :uptimes, dependent: :destroy
  belongs_to :region
  has_and_belongs_to_many :certificates

  acts_as_paranoid

  validates :provider, :country, :city, :hv_group_id, :photo_ids, presence: true
  validates :price_memory, :price_disk, :price_cpu, numericality: true
  validates :max_index_cpu, :max_index_iops, :max_index_bandwidth, numericality: true
  validate :verify_valid_country_code
  
  def provisioner_templates
    templates.where(os_distro: 'docker')
  end

  def country_name
    return unless country
    Rails.cache.fetch([self, :country_name]) do
      IsoCountryCodes.find(country).name
    end
  end

  def to_s
    "#{country_name} (#{country}), #{city}, #{provider}"
  end

  def hourly_price(memory = 512, cpu = 1, disk = 20)
    (memory * price_memory) + (cpu * price_cpu) + (disk * price_disk)
  end
  
  def monthly_price
    hourly_price * Account::HOURS_MAX
  end
  
  def self.cheapest
    where(hidden: false).min_by(&:hourly_price)
  end
  
  def frontend_uptimes
    {
      start: uptimes.first.try(:starttime).try(:to_date),
      end:   uptimes.last.try(:starttime).try(:to_date),
      downtimes: downtimes
    }
  end
  private

  def downtimes
    uptimes.downtimes.map {|obj| {date: obj.starttime.to_date, downtime: obj.downtime}}
  end
  
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
