class ServerIpAddress < ActiveRecord::Base
  
  acts_as_paranoid
  
  belongs_to :server
  
  validates :address, :server, presence: true
  
end
