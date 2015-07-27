# Creates the non-privelged OnApp user role that all cloud.net users use to interact with OnApp
# Unfortunately, permission IDs are not the same on every installation of OnApp, so we use
# the identifiers stored in `db/roles.json` as sifgnatures to match against the IDs in the
# currently connected OnApp installation
task create_onapp_role: :environment do
  # List of required permissions referenced as identifiers, eg;
  # {
  #  "identifier": "backups.convert.own",
  #  "label": "Convert own backup to template"
  # }
  required_perms = JSON.parse(
    File.read('db/roles.json')
  )

  # Get the list of permissions on the live CP, so we can map identifiers to IDs
  live_perms = {}
  squall = Squall::Role.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
  squall.permissions.each do |perm|
    live_perms[perm['identifier']] = perm['id']
  end

  # Do the actual mapping to get a list of perm IDs we can send to the API
  permission_ids = []
  required_perms.each do |perm|
    permission_ids << live_perms[perm['identifier']]
  end

  squall = Squall::Role.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
  response = squall.create(
    label: 'user',
    permission_ids: permission_ids
  )
  puts "Role created. ID is #{response['role']['id']}, set this value to the ONAPP_ROLE key in .env"
end

# Show the details of the current OnApp user role
task show_onapp_role: :environment do
  squall = Squall::Role.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
  role = squall.show 2
  puts role['permissions'].map{ |p| p['permission']['id'] }.join(',')
end

# The original jager installation of Cloud.net contains all the permissions needed
# for the cloud.net role. This little task just parses those roles. Theoretically, this
# should never needed to be run again
task save_canonical_perms: :environment do
  perms = []
  json = JSON.parse(File.read('path/to/canonical/role/json'))['role']['permissions']
  json.each do |item|
    perm = item['permission']
    perms << { identifier: perm['identifier'], label: perm['label'] }
  end

  puts perms.to_json
end
