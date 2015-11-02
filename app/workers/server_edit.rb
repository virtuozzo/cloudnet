class ServerEdit
  include Sidekiq::Worker
  sidekiq_options unique: true
  
  def perform(user_id, server_id, disk_resize, template_reload, cpu_mem_changes)
    editor = EditServerTask.new(user_id, server_id, 
                            disk_resize, template_reload, cpu_mem_changes)
    editor.edit_server
  end
end