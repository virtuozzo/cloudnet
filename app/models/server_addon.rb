class ServerAddon < ActiveRecord::Base
  
  belongs_to :addon
  belongs_to :server
  
end
