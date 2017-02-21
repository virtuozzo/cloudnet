class ServerWizard
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  include MultiStepModel
  include Billing::ServerInvoiceable

  class WizardError < StandardError; end

  ATTRIBUTES = [:location_id, :template_id, :memory, :cpus, :disk_size, :name,
                :os_type, :card_id, :user, :ip_addresses, :payment_type, :build_errors,
                :submission_path, :existing_server_id, :provisioner_role, :validation_reason,
                :invoice, :addon_ids, :ssh_key_ids]
  attr_accessor(*ATTRIBUTES)

  attr_reader :hostname

  validates :location_id, presence: true , if: :step2?
  validate :is_valid_location, if: :step2?
  # validate :no_two_vms_in_same_location, if: :step1?
  validate :reset_template_for_location_if_invalid, if: :step2?

  validates :template_id, :memory, :cpus, :disk_size, :name, presence: true, if: :step2?
  validate :is_valid_template, if: :step2?
  validate :check_user_server_limits, if: :step2?
  validate :check_minimum_template_limits, if: :step2?
  validate :within_package_if_budget_vps_package, if: :step2?
  validates :name, length: { minimum: 2, maximum: 48 }, if: :step2?
  validates_with HostnameValidator, if: :step2?

  validate :has_confirmed_email?, if: :step3?
  validate :validate_wallet_credit, if: :step3?
  validate :validate_provisioner_template, if: :step2?
  validate :ssh_key_install, if: :step2?

  validates :payment_type, inclusion: { in: %w(prepaid payg) }

  def initialize(attributes = {})
    @submission_path = Rails.application.routes.url_helpers.servers_create_path
    @build_errors = []
    unless attributes.nil?
      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end
  end

  def total_steps
    (enough_wallet_credit? && user.confirmed?) ? [current_step, 2].max : 3
  end

  def current_step_name
    case current_step
    when 1
      @current_step_name = 'location'
    when 2
      @current_step_name = 'resources'
    when 3
      @current_step_name = 'confirmation'
    end
  end

  def hostname=(value)
    @hostname = value.gsub(/http(s)?:\/\//, '')
  end

  def id
    nil
  end

  def save
    # Overridden method, do nothing!
    true
  end

  def save!
    # Overridden method, do nothing!
    true
  end

  def no_errors?
    errors.messages.count == 0
  end

  def location
    @location ||= Location.find_by_id(location_id) if location_id
  end

  def template
    @template ||= Template.where(location_id: location_id).find_by_id(template_id) if location && template_id
    @template
  end

  def location=(location)
    self.location_id = location.id
  end

  def template=(template)
    self.template_id = template.id
  end

  def card
    @card ||= BillingCard.where(account: user.account).find_by_id(card_id)
    @card
  end

  def card=(card)
    self.card_id = card.try(:id)
  end
  
  def addons
    @addons ||= Addon.where(id: addon_ids) unless addon_ids.blank?
    @addons || []
  end

  def payment_type
    @payment_type || Server::TYPE_PREPAID
  end

  def prepaid?
    payment_type == Server::TYPE_PREPAID
  end

  def payg?
    payment_type == Server::TYPE_PAYG
  end

  # Create the server in Cloud.net's database
  def save_server_details(server, user)
    disk_size = server['total_disk_size'].to_i

    Server.create(
      identifier:             server['identifier'],
      name:                   name,
      hostname:               hostname,
      user:                   user,
      built:                  server['built'],
      suspended:              server['suspended'],
      locked:                 server['locked'],
      remote_access_password: server['remote_access_password'],
      root_password:          server['initial_root_password'],
      hypervisor_id:          server['hypervisor_id'],
      cpus:                   server['cpus'],
      memory:                 server['memory'],
      disk_size:              disk_size > 0 ? disk_size.to_s : self.disk_size,
      os:                     server['operating_system'],
      os_distro:              template.os_distro,
      template:               template,
      location:               location,
      bandwidth:              bandwidth,
      payment_type:           'prepaid',
      provisioner_role:       provisioner_role,
      validation_reason:      validation_reason,
      addon_ids:              addon_ids
    )
  end

  def create_server
    create_or_edit_server(:create)
  end

  def edit_server(old_server_specs)
    set_old_server_specs(old_server_specs)
    create_or_edit_server(:edit)
  end

  def resources_changed?
    @resources_changed ||= server_name_changed_only? ? false : server_changed? || addons_changed? || ip_addresses_changed?
  end

  # Returns Server object for type = :create and true for :edit
  def create_or_edit_server(type = :create)
    if type == :edit && resources_changed?
      # Issue a credit note for the server's old specs for the time remaining during this
      # invoicable month. We will then charge them for the newly resized server as if it were
      # new.
      @credit_note_for_time_remaining = @old_server_specs.create_credit_note_for_time_remaining
    end

    if type == :create
      # Generate invoice, use credit notes if any, finally charge payment receipts
      charge_wallet
      # Build the server through the Onapp API
      request_server_build
      charging_paperwork
      @newly_built_server
    else
      # Generate invoice, use credit notes if any, finally charge payment receipts
      charge_wallet if resources_changed?
      # Edit the server through the Onapp API
      request_server_edit
      charging_paperwork if resources_changed?
      true
    end
  rescue WizardError
    nil # Simply a means to abort the server creation process at any point
  ensure
    if @build_errors.length > 0
      # Refund any payment receipts used
      if @payment_receipts_used.present?
        PaymentReceipt.refund_used_notes(@payment_receipts_used)
        user.account.create_activity :refund_used_payment_receipts, owner: user, params: { notes: @payment_receipts_used }
      end

      # Refund any credit notes used
      if @notes_used.present?
        CreditNote.refund_used_notes(@notes_used)
        user.account.create_activity :refund_used_notes, owner: user, params: { notes: @notes_used }
      end

      # Clean up the lingering invoice and server
      if @invoice
        @invoice.save
        @invoice.really_destroy!
      end

      # Delete any credit notes given for server edit
      if @credit_note_for_time_remaining
        @credit_note_for_time_remaining.destroy
        user.account.create_activity :delete_credit_note, owner: user, params: { notes: @credit_note_for_time_remaining }
      end

      # Undo server creation
      @newly_built_server.destroy if @newly_built_server

      # Expire cache if any
      user.account.expire_wallet_balance
    end
  end

  # Create an actual server. This is the whole point of cloud.net!
  def request_server_build
    remote = CreateServer.new(self, user).process
    if remote.nil? || remote['id'].nil?
      @build_errors.push('Could not create server on remote system. Please try again later')
      fail WizardError
    end
    @newly_built_server = save_server_details(remote, user)
  rescue Faraday::Error::ClientError, StandardError => e
    ErrorLogging.new.track_exception(
      e,
      extra: {
        current_user: user,
        source: 'CreateServerTask'
      }
    )
    @build_errors.push('Could not create server on remote system. Please try again later')
    raise WizardError
  end

  def request_server_edit
    return unless server_changed?

    ServerEdit.perform_async(user.id, existing_server_id,
              disk_resize, template_reload, cpu_mem_changes)
  end

  # TODO: old_server_spec can be taken from onapp API
  def disk_resize
    disk_size == @old_server_specs.disk_size ? false : @old_server_specs.disk_size
  end

  def template_reload
    template_id == @old_server_specs.template_id ? false : template_id
  end

  def cpu_mem_changes
    changed = @old_server_specs.cpus != cpus ||
              @old_server_specs.memory != memory ||
              @old_server_specs.name != name
    changed ? old_server_cpu_mem : false
  end

  def server_name_changed_only?
    !template_reload &&
    !disk_resize &&
    @old_server_specs.cpus == cpus &&
    @old_server_specs.memory == memory &&
    @old_server_specs.name != name
  end

  def old_server_cpu_mem
    { "cpus" => @old_server_specs.cpus,
      "memory" => @old_server_specs.memory,
      "name" => @old_server_specs.name
    }
  end
  
  def addons_changed?
    @old_server_specs.addon_ids.map(&:to_i).uniq.sort != addon_ids.map(&:to_i).uniq.sort
  end

  def server_changed?
    cpu_mem_changes || template_reload || disk_resize
  end

  def ip_addresses_changed?
    @old_server_specs.ip_addresses != ip_addresses
  end

  def persisted?
    false
  end

  def remaining_resources
    max = remaining_server_resources
    min = minimum_resources
    resources = []

    [:memory, :cpus, :disk_size].each do |element|
      resources << { min: min[element], max: max[element], field: element.to_s }
    end

    resources
  end

  def can_create_new_server?
    user.servers.count < user.vm_max
  end

  def has_minimum_resources?
    minimum = minimum_resources
    remaining_resources = remaining_server_resources
    remaining_resources.delete(:vms)
    remaining_resources.each { |k, v| return false if minimum[k] > v }
    true
  end

  def packages
    return nil unless location
    packages = location.packages
    packages.select { |package| @user ? has_enough_remaining_resources?(package) : true }
  end

  def bandwidth
    ((location.inclusive_bandwidth / 1024.0) * memory.to_i).ceil
  end

  def string_wizard_params
    wizard_params.map {|k,v| "\"#{k}\": #{v},"}.join.slice(0..-2)
  end

  def params_values?
    val = wizard_params.reduce(0){|m,o| o[1].to_i+m}
    val.nil? or val <= 0 ? false : true
  end

  def package_matched
    attr = %i( cpus memory disk_size )
    packages.find {|p| p.slice(*attr).symbolize_keys == wizard_params }.try(:id)
  end

  def matches_package?(package)
    matches = true
    [:memory, :disk_size, :cpus].each do |item|
      matches = false if send(item).to_i != package.send(item).to_i
    end
    matches
  end

  def enough_wallet_credit?
    return false if template.nil?
    return false if user.nil?
    server = Server.find existing_server_id if !existing_server_id.nil?
    coupon_percentage = user.account.coupon.present? ? user.account.coupon.percentage_decimal : 0
    if server
      credit = server.generate_credit_item(CreditNote.hours_till_next_invoice(user.account))
      net_cost = credit[:net_cost] * (1 - coupon_percentage)
      net_cost = 0 if server.in_beta?
    else
      net_cost = 0
    end

    billable_today = cost_for_hours(Invoice.hours_till_next_invoice(user.account)) * (1 - coupon_percentage)
    (billable_today.to_f == 0.0) || (((user.account.remaining_balance * -1) + net_cost).to_f >= billable_today.to_f)
  end

  private

  def wizard_params
    {cpus: cpus || 0, memory: memory || 0, disk_size: disk_size || 0}
  end

  def has_enough_remaining_resources?(package)
    max = remaining_server_resources
    max.delete(:vms)
    max.each { |k, v| return false if package.send(k.to_sym) > v }
    true
  end

  def reset_template_for_location_if_invalid
    self.template_id = nil if template.nil?
  end

  def no_two_vms_in_same_location
    locations = user.servers.map { |s| s.location_id.to_s }

    if locations.include?(location_id)
      errors.add(:location, 'could not be selected. You already have a server in this location')
    end
  end

  def is_valid_location
    errors.add(:location, 'does not exist') if location.nil?
    errors.add(:location, 'is unavailable') if !location.nil? && existing_server_id.nil? && location.hidden?
  end

  def is_valid_template
    errors.add(:template, 'does not exist') if template.nil?
  end

  def check_minimum_template_limits
    template = self.template
    min_resources = minimum_resources
    return false if template.nil?
    min_memory = [template.min_memory, min_resources[:memory]].max
    min_disk_size = [template.min_disk, min_resources[:disk_size]].max

    if memory.to_i < min_memory
      errors.add(:memory, "needs a minimum of #{min_memory} MB")
    end

    if disk_size.to_i < min_disk_size
      errors.add(:disk_size, "needs a minimum of #{min_disk_size} GB")
    end

    if cpus.to_i < min_resources[:cpus]
      errors.add(:cpus, "needs a minimum of #{min_resources[:cpus]} CPU Core(s)")
    end
  end

  def check_user_server_limits
    resources = remaining_server_resources

    if memory.to_i > resources[:memory]
      errors.add(:memory, "is limited to a total of #{user.memory_max} MB across all servers. Please contact support to get this limit increased")
    end

    if cpus.to_i > resources[:cpus]
      errors.add(:cpus, "are limited to a total of #{user.cpu_max} Cores across all servers")
    end

    if disk_size.to_i > resources[:disk_size]
      errors.add(:disk_size, "is limited to a total of #{user.storage_max} GB across all servers. Please contact support to get this limit increased")
    end

    # check only for new server creations
    if existing_server_id.nil? && resources[:vms] < 1
      errors.add(:vms, "are limited to a total of #{user.vm_max}. Please contact support to get this limit increased")
    end
  end

  def minimum_resources
    { memory: 512, cpus: 1, disk_size: 20 }
  end

  def remaining_server_resources
    if user
      servers = user.servers
      memory_used = servers.map(&:memory).reduce(:+) || 0
      storage_used = servers.map(&:disk_size).reduce(:+) || 0
      cpu_used = servers.map(&:cpus).reduce(:+) || 0

      {
        memory:       user.memory_max - memory_used,
        cpus:         user.cpu_max - cpu_used,
        disk_size:    user.storage_max - storage_used,
        vms:          user.vm_max - servers.count
      }
    else
      { memory: 7680, cpus: 4, disk_size: 100, vms: 3 }
    end
  end

  def within_package_if_budget_vps_package
    return false unless location
    return true if !location.budget_vps? #&& !existing_server_id.nil?

    matches = false
    packages.each do |package|
      matches = true if matches_package?(package)
    end

    errors.add(:base, "Please select a package (or the template you've chosen is incompatible with this package)") unless matches
    matches
  end

  def validate_wallet_credit
    errors.add(:base, 'You do not have enough credit to run this server until next invoice date. Please top up your Wallet.') unless enough_wallet_credit?
  end

  def validate_provisioner_template
    if !provisioner_role.blank? && template_id.to_s != location.provisioner_templates.first.id.to_s
      errors.add(:base, 'Invalid template for provisioner')
    end
  end

  def has_confirmed_email?
    errors.add(:base, 'Please confirm your email address before creating a server') if user && !user.confirmed?
  end
  
  def ssh_key_install
    errors.add(:base, 'SSH keys are invalid for selected template') if !ssh_key_ids.blank? && !template.blank? && key_install_unsupported?
  end
  
  def key_install_unsupported?
    %w(windows freebsd).any? { |os| template.os_type.include? os }
  end
end
