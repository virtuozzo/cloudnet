class RiskyCard < ActiveRecord::Base
  
  acts_as_paranoid
  
  belongs_to :account
  
  validates :fingerprint, :account, presence: true
  
end
