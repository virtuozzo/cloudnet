class ProcessAddons < BaseTask
  attr_reader :server
  
  def initialize(server)
    @server = server
  end
  
  def process
    AddonTasks.new.perform(:process_task, server) #rescue nil
    SupportTasks.new.perform(:notify_addons_request, server.user, [server]) #rescue nil
  end
end
