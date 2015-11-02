json.array! @keys do |key|
  json.partial! 'keys/key', key: key
end
