class Package < ActiveRecord::Base
  belongs_to :location
  validates :location, :memory, :cpus, :disk_size, :ip_addresses, presence: true
  default_scope { order('memory ASC, cpus ASC, disk_size ASC') }

  def hourly_cost
    location.hourly_price(memory, cpus, disk_size)
  end

  def monthly_cost
    hourly_cost * Account::HOURS_MAX
  end

  def bandwidth
    (location.inclusive_bandwidth / 1024.0) * ((memory / 128).floor * 128)
  end

  def to_s
    "#{memory} MB RAM, #{cpus} CPUs, #{disk_size} GB Disk, #{bandwidth} GB Bandwidth, #{ip_addresses} IP's"
  end
end
