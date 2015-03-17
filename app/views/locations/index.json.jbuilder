json.array! @locations do |location|
  json.partial! 'locations/location', location: location
end
