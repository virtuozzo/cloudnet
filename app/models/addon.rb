class Addon < ActiveRecord::Base
  
  has_many :server_addons
  has_many :servers, through: :server_addons
  
  scope :available, -> { where(hidden: false).order(:created_at) }
  
  def self.available_tasks
    { "DirectAdmin" => "DirectAdmin::License" }
  end
  
end
