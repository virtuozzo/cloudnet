# For representing more than one at a time
module ServersRepresenter
  include BaseRepresenter
  include Representable::JSON::Collection
  items extend: ServerRepresenter
end
