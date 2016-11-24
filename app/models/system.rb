class System < ActiveRecord::Base

  validates :key, :value, presence: true
  validates_uniqueness_of :key, allow_nil: false


  def self.get(key, default: '')
    key = key.to_s
    lock.find_by!(key: key).value
  rescue ActiveRecord::RecordNotFound
    default
  end

  def self.set(key, value)
    key = key.to_s
    find_by!(key: key).update_attribute(:value, value)
  rescue ActiveRecord::RecordNotFound
    create(key: key, value: value)
  end

  def self.clear(key)
    set(key, '')
  end
end
