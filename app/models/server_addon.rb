class ServerAddon < ActiveRecord::Base
  acts_as_paranoid
  
  after_destroy :reset_process
  
  belongs_to :addon
  belongs_to :server
  
  def reset_process
    update! notified_at: nil, processed_at: nil
  end
  
end
