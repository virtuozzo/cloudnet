class ProcessAddons < BaseTask
  attr_reader :server
  
  def initialize(server)
    @server = server
  end
  
  def process
    SupportTasks.new.perform(:notify_addons_request, server.user, [server]) #rescue nil
  end
end
