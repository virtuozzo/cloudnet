class Region < ActiveRecord::Base
  has_many :locations, dependent: :nullify
  
  validates :name, presence: true
end
