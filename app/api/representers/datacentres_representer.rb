# For representing more than one at a time
module DatacentresRepresenter
  include BaseRepresenter
  include Representable::JSON::Collection
  items extend: DatacentreRepresenter
end
