class UserServerCount < ActiveRecord::Base
  DO_NOT_COUNT_VM_LASTING_LESS_DAYS = 2
  
  belongs_to :user
  validates :user, :date, :servers_count, presence: true
  
  class << self
    # do not count servers lasting less than DO_NOT_COUNT_VM_LASTING_LESS_DAYS
    def deleted_servers(user, day)
      user.servers.only_deleted.where(
        "created_at < ? AND
         deleted_at > ? AND
         deleted_at - created_at > INTERVAL '#{DO_NOT_COUNT_VM_LASTING_LESS_DAYS} days'", 
         next_midnight(day),
         day.midnight
      )
    end 
    
    # do not count servers lasting less than DO_NOT_COUNT_VM_LASTING_LESS_DAYS
    def existing_servers(user, day)
      user.servers.where(
        "created_at < ? AND
         ? - created_at > INTERVAL '#{DO_NOT_COUNT_VM_LASTING_LESS_DAYS} days'", 
         next_midnight(day),
         Time.now
      )
    end
    
    # do not count servers lasting less than DO_NOT_COUNT_VM_LASTING_LESS_DAYS
    def all_servers(user, day)
      user.servers.with_deleted.where(
        "(created_at < ? AND
         deleted_at > ? AND
         deleted_at - created_at > INTERVAL '#{DO_NOT_COUNT_VM_LASTING_LESS_DAYS} days')
         OR
         (deleted_at IS NULL AND
         created_at < ? AND
         ? - created_at > INTERVAL '#{DO_NOT_COUNT_VM_LASTING_LESS_DAYS} days')", 
         next_midnight(day),
         day.midnight,
         next_midnight(day),
         Time.now
      )
    end
  
    def next_midnight(day)
      day.midnight + 1.day
    end
  end

  def deleted_servers
    return if user.nil? || date.nil?
    self.class.deleted_servers(user, date)
  end
  
  def existing_servers
    return if user.nil? || date.nil?
    self.class.existing_servers(user, date)
  end
  
  def all_servers
    return if user.nil? || date.nil?
    self.class.all_servers(user, date)
  end
end
