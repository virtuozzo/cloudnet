# Serialise server objects
module ServerRepresenter
  include BaseRepresenter

  property :id
  property :created_at
  property :updated_at
  property :name
  property :hostname
  property :memory
  property :cpus
  property :disk_size
  property :bandwidth, render_filter: ->(bw, server, app) { bw.to_f }
  property :state
  property :root_password, as: :initial_root_password
  collection :server_ip_addresses, as: :ip_addresses, extend: IpAddressRepresenter
  property :template, extend: TemplateRepresenter
  property :location_id, as: :datacenter_id
  collection :server_events, as: :transactions do
    property :transaction_updated
    property :action
    property :status
  end
end