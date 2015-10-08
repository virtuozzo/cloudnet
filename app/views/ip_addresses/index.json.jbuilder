json.array! @ip_addresses do |ip_address|
  json.partial! 'ip_addresses/ip_address', ip_address: ip_address
end
