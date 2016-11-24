class Template < ActiveRecord::Base
  belongs_to :location
  has_many :servers
  has_many :build_checker_data, class_name: BuildChecker::Data::BuildCheckerDatum, dependent: :destroy

  validates :identifier, :os_type, :onapp_os_distro, :os_distro, :name, :location, presence: true

  DEFAULT_SWAP_GB = 1

  def to_s
    "#{name} - #{os_distro} (#{location})"
  end

  def min_disk
    if os_type != 'windows'
      # We need to account for swap on linux
      read_attribute(:min_disk) + DEFAULT_SWAP_GB
    else
      read_attribute(:min_disk)
    end
  end

  def required_swap
    if os_type == 'windows'
      return 0
    else
      return DEFAULT_SWAP_GB
    end
  end

  def self.distro_name(onapp_distro, name, os_type)
    name = name.downcase
    onapp_distro = onapp_distro.downcase
    os_type = os_type.downcase

    # Group all Windows Templates under the Windows OS Type
    return 'windows' if os_type.include? 'windows'

    # Red Hat needs some special attention
    return 'rhel' if name.include?('red hat') || name.include?('rhel')

    # These can just return the type if it matches
    ['ubuntu', 'debian' 'centos', 'gentoo', 'fedora', 'slackware', 'opensuse', 'cloudlinux'].each do |type|
      return type if name.include? type
    end

    # If all else fails, return the first word of the template
    name.split(' ')[0]
  end
end
