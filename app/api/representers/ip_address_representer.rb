# Serialise template objects
module IpAddressRepresenter
  include BaseRepresenter

  property :address
  property :netmask
  property :network
  property :broadcast
  property :gateway
  property :primary
end
