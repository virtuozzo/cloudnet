# Temporary measure whilst we figure out how to automatically add Locations, Templates and
# Packages.
task cache_locations: :environment do
  path = "#{Rails.root}/locations.json"
  squall = Squall::Template.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
  store = squall.template_store
  File.open(path, 'w') do |f|
    f.write(store.to_json)
  end
  puts "Locations written to #{path}"
end
