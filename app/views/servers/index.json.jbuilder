json.array! @servers do |server|
  json.partial! 'server', server: server
end
