class RiskyIpAddress < ActiveRecord::Base
  
  acts_as_paranoid
  
  belongs_to :account
  
  validates :ip_address, :account, presence: true
  
end
