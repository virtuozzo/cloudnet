json.extract!(
  ip_address,
  :id,
  :address,
  :netmask,
  :network,
  :broadcast,
  :gateway,
  :primary
)

json.created_at ip_address.created_at.iso8601
json.updated_at ip_address.updated_at.iso8601
