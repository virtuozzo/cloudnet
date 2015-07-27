class Uptime < ActiveRecord::Base
  belongs_to :location
  validates :location, presence: true
  default_scope {order('starttime ASC')}
  scope :downtimes, -> {select(:downtime, :starttime).where("downtime > 0")}
  
  MAX_DATA_PER_LOCATION = 150 #days
  
  def self.create_or_update(params=nil)
    new(params).save_or_update
  end
  
  def starttime=(unix_sec)
    write_attribute(:starttime, Time.at(unix_sec))
  end
  
  def save_or_update
    if new_record? and exists_in_db?
      # updating existing record based on location_id and starttime
      update_needed? ? for_update.update(updated_attr) : false
    else
      result = save
      remove_old_data if data_number_exceeded?
      result
    end
  end
  
  private
  
  def updated_attr
    {
      avgresponse: avgresponse,
      downtime: downtime,
      uptime: uptime,
      unmonitored: unmonitored
    }
  end
  
  def remove_old_data
    self.class.where(location_id: self.location_id).order(:starttime)
        .limit(number_of_records - MAX_DATA_PER_LOCATION)
        .destroy_all
  end

  def data_number_exceeded?
    number_of_records > MAX_DATA_PER_LOCATION
  end

  def number_of_records
    self.class.where(location_id: self.location_id).count
  end
    
  def for_update
    @for_update ||= Uptime.where(location_id: location_id, starttime: starttime).first
  end
  
  def exists_in_db?
    !for_update.nil?
  end
  
  def update_needed?
    !is_same_as?(for_update)
  end
  
  def is_same_as?(other)
    self.attributes.slice(*updated_attr.keys.map(&:to_s)) == other.attributes.slice(*updated_attr.keys.map(&:to_s))
  end
end
