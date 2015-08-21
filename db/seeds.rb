# Create an admin user
admin = User.find_or_create_by(email: 'admin@cloud.net') do |u|
  u.full_name = 'Cloud Admin'
  u.password = 'adminpassword'
  u.admin = true
end
admin.confirm! unless admin.confirmed?

Location.find_or_create_by(provider: 'vCloud') do |l|
  l.id = 1
  l.latitude = '40.7127'
  l.longitude = '-74.0059'
  l.country = 'US'
  l.city = 'vCenter'
  l.hv_group_id = 8
  l.hidden = false
  l.price_memory = 0.0
  l.price_disk = 0.0
  l.price_cpu = 0.0
  l.price_bw = 0.0
  l.photo_ids = '62239001'
  l.price_ip_address = 0.0
  l.budget_vps = false
  l.inclusive_bandwidth = 100
  l.ssd_disks = false
  l.max_index_cpu = 0
  l.max_index_iops = 0
  l.max_index_bandwidth = 0
  l.max_index_uptime = 0.0
  l.summary = ''
end

Location.find_or_create_by(provider: 'vCenter') do |l|
  l.id = 2
  l.latitude = '37.7833'
  l.longitude = '-122.4167'
  l.country = 'US'
  l.city = 'vCenter'
  l.hv_group_id = 8
  l.hidden = false
  l.price_memory = 0.0
  l.price_disk = 0.0
  l.price_cpu = 0.0
  l.price_bw = 0.0
  l.photo_ids = '64754607'
  l.price_ip_address = 0.0
  l.budget_vps = false
  l.inclusive_bandwidth = 100
  l.ssd_disks = false
  l.max_index_cpu = 0
  l.max_index_iops = 0
  l.max_index_bandwidth = 0
  l.max_index_uptime = 0.0
  l.summary = ''
end

VCDSetup.import_templates
