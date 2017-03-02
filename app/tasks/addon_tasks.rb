# TODO: Make this a background task
class AddonTasks < BaseTasks
  
  def perform(action, server)
    @server = server
    run_task(action, server)
  end
  
  private
  
  def process_task(server)
    server.server_addons.with_deleted.where(processed_at: nil).each do |server_addon|
      task = server_addon.addon.task
      next if task.blank?
      task.constantize.new(server_addon).process
      server_addon.update_attribute :processed_at, Time.now
    end
  end
  
  def allowable_methods
    super + [:process_task]
  end
  
end
