class Region < ActiveRecord::Base
  has_many :locations, dependent: :nullify

  scope :active, -> {
    where(id: Region.used_regions_ids).order(:id)
  }
  scope :active_regions, -> {
    where(id: Region.used_regions_ids).order(:id).map{|reg| [reg.name, reg.id]}
  }
  scope :used_regions_ids, -> { 
    Location.select('region_id').where.not(region_id: nil, hidden: true).group('region_id').map(&:region_id) 
  }

  validates :name, presence: true, uniqueness: true
  
  def active_locations
    locations.where(hidden: false)
  end

end
