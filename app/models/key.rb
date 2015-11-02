class Key < ActiveRecord::Base
  
  acts_as_paranoid
  
  belongs_to :user
  
  validates :title, :key, presence: true
  
end
