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
  validates :max_index_cpu, :max_index_iops, :max_index_bandwidth, :max_index_uptime, numericality: true
  validate :verify_valid_country_code

  def country_name
    return unless country
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
  
  def frontend_uptimes
    {
      start: uptimes.first.try(:starttime).try(:to_date),
      end:   uptimes.last.try(:starttime).try(:to_date),
      downtimes: downtimes
    }
  end

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

  def credentials
    [ENV["#{key}_USER"], ENV["#{key}_PASS"]]
  end

  def api
    OnappBlanketAPI.new.connection credentials
  end

  def import_templates
    if templates.count > 1
      raise "Aborting. There are already installed templates"
    end
    html = open(
      "#{ENV['ONAPP_CP']}/vapps/new",
      http_basic_authentication: credentials,
      ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
    )
    doc = Nokogiri::HTML html
    options = doc.css '#vapp_vapp_template_id option'
    options.each do |template|
      id = template.attributes['value'].value
      vmid = get_vmid(id)
      next unless vmid
      Template.create!(
        location: self,
        identifier: id,
        vmid: vmid,
        name: template.content,
        os_type: 'vCD',
        onapp_os_distro: 'vCD',
        os_distro: 'vCD'
      )
    end
  end

  def get_vmid(id)
    details = api.get(
      "/vapp_templates/#{id}/hardware_customization",
      params: { vdc_id: vdc_id }
    )
    begin
      details.identifier
    rescue NoMethodError
      false
    end
  end

  def vdc_ids
    [api.get('vdcs').first.vdc.id]
  end

  def hd_net_data
    vdc_id ||= vdc_ids.first
    @hd_net_data ||= api.get("vdcs/#{vdc_id}/data")
  end

  def network_ids
    hd_net_data.networks.map(&:id)
  end

  def hd_policies
    hd_net_data.data_stores.map(&:id)
  end

  def import_vcd_ids
    self.vdc_id = vdc_ids.first
    self.vcd_network_id = network_ids.first
    self.vcd_hd_policy = hd_policies.first
    save!
  end
end
