class ServerEdit
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed,
                  unique_args: ->(args) { [ args[1] ] }
  sidekiq_options :retry => false

  def perform(user_id, server_id, disk_resize, template_reload, cpu_mem_changes)
    editor = EditServerTask.new(user_id, server_id,
                            disk_resize, template_reload, cpu_mem_changes, logger)
    editor.edit_server
  end
end