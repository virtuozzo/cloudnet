class ServerWizard
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  include MultiStepModel
  include Billing::ServerInvoiceable

  class WizardError < StandardError; end

  ATTRIBUTES = [:location_id, :template_id, :memory, :cpus, :disk_size, :name,
                :os_type, :card_id, :user, :ip_addresses, :payment_type, :build_errors,
                :submission_path, :existing_server_id]
  attr_accessor(*ATTRIBUTES)

  attr_reader :hostname

  validates :location_id, presence: true, if: :step1?
  validate :is_valid_location, if: :step1?
  # validate :no_two_vms_in_same_location, if: :step1?
  validate :reset_template_for_location_if_invalid, if: :step1?

  validates :template_id, :memory, :cpus, :disk_size, :name, presence: true, if: :step2?
  validate :is_valid_template, if: :step2?
  validate :check_user_server_limits, if: :step2?
  validate :check_minimum_template_limits, if: :step2?
  validate :within_package_if_budget_vps_package, if: :step2?
  validates :name, length: { minimum: 2, maximum: 48 }, if: :step2?
  validates_with HostnameValidator, if: :step2?

  validate :valid_card?, if: :step3?
  validate :enough_payg_credit?, if: :step3?

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


  def self.total_steps
    3
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
    @location = Location.where(hidden: false).find_by_id(location_id) if location_id
  end

  def template
    @template = Template.where(hidden: false, location_id: location_id).find_by_id(template_id) if location && template_id
    @template
  end

  def location=(location)
    self.location_id = location.id
  end

  def template=(template)
    self.template_id = template.id
  end

  def card
    @card = BillingCard.where(account: user.account).find_by_id(card_id)
    @card
  end

  def card=(card)
    self.card_id = card.id
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
      payment_type:           payment_type.to_sym
    )
  end

  def create_server
    create_or_edit_server(:create)
  end

  def edit_server(old_server_specs)
    @old_server_specs = old_server_specs
    create_or_edit_server(:edit)
  end

  def create_or_edit_server(type = :create)
    if type == :edit
      # Issue a credit note for the server's old specs for the time remaining during this
      # invoicable month. We will then charge them for the newly resized server as if it were
      # new.
      @credit_note_for_time_remaining = @old_server_specs.create_credit_note_for_time_remaining
    end
    # Calculate how much to charge for this server. Calculates time remaining in month and
    # user's credit notes. Does not actually make the charge, that happens later.
    auth_charge

    if type == :create
      # Build the server through the Onapp API
      request_server_build
    else
      # Edit the server through the Onapp API
      request_server_edit
    end

    # Actually make the charge against a card and fill in the relevant paperwork
    make_charge

    @newly_built_server
  rescue WizardError
    nil # Simply a means to abort the server creation process at any point
  ensure
    if @build_errors.length > 0
      @credit_note_for_time_remaining.destroy if @credit_note_for_time_remaining
      CreditNote.refund_used_notes(@notes_used)
      user.account.create_activity :refund_used_notes, owner: user, params: { notes: @notes_used }
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
  rescue Faraday::Error::ClientError => e
    ErrorLogging.new.track_exception(
      e,
      extra: {
        current_user: user,
        source: 'CreateServerTask',
        faraday: e.response
      }
    )
    @build_errors.push('Could not create server on remote system. Please try again later')
    raise WizardError
  end

  def request_server_edit
    ServerTasks.new.perform(:edit, user.id, existing_server_id)
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
    remaining_server_resources.each { |k, v| return false if minimum[k] > v }
    true
  end

  def packages
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

  private

  def wizard_params
    {cpus: cpus || 0, memory: memory || 0, disk_size: disk_size || 0}
  end

  def has_enough_remaining_resources?(package)
    max = remaining_server_resources
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
  end

  def is_valid_template
    errors.add(:template, 'does not exist') if template.nil?
  end

  def check_minimum_template_limits
    template = self.template
    min_resources = minimum_resources
    return false if template.nil?

    if memory.to_i < template.min_memory
      errors.add(:memory, "is not enough for the template selected. The template needs a minimum of #{template.min_memory} MB")
    end

    if disk_size.to_i < template.min_disk
      errors.add(:disk_size, "is not enough for the template selected. The template needs a minimum of #{template.min_disk} GB")
    end

    if cpus.to_i < min_resources[:cpus]
      errors.add(:cpus, "need a minimum of #{min_resources[:cpus]} CPU Core(s)")
    end
  end

  def check_user_server_limits
    resources = remaining_server_resources

    if memory.to_i > resources[:memory]
      errors.add(:memory, "is limited to a total of #{user.memory_max} MB across all servers. Please contact support to get this limit increased")
    end

    # if cpus.to_i > resources[:cpus]
    #   errors.add(:cpus, "are limited to a total of #{user.cpu_max} Cores across all servers")
    # end

    if disk_size.to_i > resources[:disk_size]
      errors.add(:disk_size, "is limited to a total of #{user.storage_max} GB across all servers. Please contact support to get this limit increased")
    end
  end

  def minimum_resources
    { memory: 128, cpus: 1, disk_size: 6 }
  end

  def remaining_server_resources
    if user
      servers = user.servers
      memory_used = servers.map(&:memory).reduce(:+) || 0
      storage_used = servers.map(&:disk_size).reduce(:+) || 0

      {
        memory:       user.memory_max - memory_used,
        cpus:         user.cpu_max,
        disk_size:    user.storage_max - storage_used
      }
    else
      { memory: 7680, cpus: 4, disk_size: 100 }
    end
  end

  def within_package_if_budget_vps_package
    return true unless location.budget_vps?

    matches = false
    packages.each do |package|
      matches = true if matches_package?(package)
    end

    errors.add(:base, "This location requires a package to be chosen (or the template you've chosen is incompatible with this package)") unless matches
    matches
  end

  def valid_card?
    if prepaid? && !card.present?
      errors.add(:base, 'Card is not valid or not present')
    end
  end

  def enough_payg_credit?
    if payg? && user.account.payg_server_days(self) < 1
      errors.add(:base, 'You do not have enough PAYG credit to run this server for more than 24 hours. Please add more PAYG credit')
    end
  end
end
