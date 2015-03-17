# Server events are created and logged by Onapp, not by Cloud.net. They are collected through
# Squall#transactions(server_identifier).
class ServerEvent < ActiveRecord::Base
  include ServerEvent::Status
  belongs_to :server
  validates :action, :status, :server, presence: true
end
