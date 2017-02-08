class EditServerTask
  def initialize(user_id, server_id, old_disk_size, template_id, old_params, logger = nil)
    @user = User.find(user_id)
    @server = Server.find(server_id)
    @old_params = old_params
    @old_disk_size = old_disk_size
    @template_id = template_id
    @squall_vm   = Squall::VirtualMachine.new(*squall_params)
    @squall_disk = Squall::Disk.new(*squall_params)
    @logger = logger
  end

  def edit_server
    edit_state_on
    create_sift_event
    tasks_order.each do |task|
      log_task_process(task)
      verifier = CoreTransactionVerifier.new(@user.id, @server.id)
      verifier.perform_transaction(synchronous_call: synchronous_task?(task)) {send(task)}
    end
  ensure
    edit_state_off
  end

  def tasks_order
    @tasks_order ||= begin
      order = []
      order << :change_params     if increasing_memory?
      order << :resize_disk       if increasing_disk_size? && linux_based?
      order << :rebuild_template  if template_changed?
      order << :resize_disk       if decreasing_disk_size? && linux_based? && non_internal_storage?
      order << :change_params     if decreasing_memory?
      order
    end
  end

  private

    def change_params
      log_task_process(params_options)
      @squall_vm.edit(@server.identifier, params_options)
    end

    def resize_disk
      log_task_process(disk_options)
      @squall_disk.edit(primary_disk_id, disk_options)
    end

    def rebuild_template
      log_task_process(template_options)
      @squall_vm.build(@server.identifier, template_options)
    end

    def edit_state_on
      @server.no_auto_refresh!
      @server.update_attribute(:state, :building)
    end

    def edit_state_off
      # force refresh before other workers can perform update
      ServerTasks.new.perform(:refresh_server, @user.id, @server.id, :force_update)
      @server.auto_refresh_on!
    end

    def increasing_disk_size?
      disk_size_changed? && @old_disk_size < @server.disk_size
    end

    def decreasing_disk_size?
      disk_size_changed? && @old_disk_size > @server.disk_size
    end

    def increasing_memory?
      params_changed? && @old_params["memory"] < @server.memory
    end

    def decreasing_memory?
      (params_changed? && @old_params["memory"] > @server.memory) ||
      (params_changed?  && !increasing_memory?)
    end

    def linux_based?
      @server.os == 'linux'
    end

    #FIXME: Find a way to detect Internal Storage disks
    def non_internal_storage?
      true
    end

    def params_changed?
      @old_params != false
    end

    def disk_size_changed?
      @old_disk_size != false
    end

    def template_changed?
      @template_id != false
    end

    def primary_disk_id
      disks = @squall_disk.vm_disk_list(@server.identifier)
      disks.select{|d| d['primary'] == true}.first['id']
    end

    def disk_options
      {disk_size: @server.disk_size - 1}
    end

    def template_options
      {
        template_id: template.identifier,
        required_startup: 1
      }
    end

    def params_options
      {
        label: @server.name,
        cpus: @server.cpus,
        memory: @server.memory
      }
    end

    def template
      @template ||= Template.find(@template_id)
    end

    def synchronous_task?(task)
      #call asynchronously if the change is in VM label only
      task == :change_params && change_params_task_only_changes_label? ? false : true
    end

    def change_params_task_only_changes_label?
      old_params = @old_params.symbolize_keys
      changes =  params_options.delete_if {|k,v| old_params[k] == v }.count
      changes == 1 ? true : false
    end

    def squall_params
      [uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password]
    end

    def log_task_process(task)
      return unless @logger
      @logger.info "Processing #{task} for server #{@server.id} by user #{@user.id}"
    end

    def create_sift_event
      CreateSiftEvent.perform_async("update_server", @server.sift_server_properties)
    rescue StandardError => e
      ErrorLogging.new.track_exception(e, extra: { user: @user.id, source: 'EditServerTask#create_sift_event' })
    end
end
