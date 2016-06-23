# For representing more than one at a time
module DatacentersRepresenter
  include BaseRepresenter
  include Representable::JSON::Collection
  items extend: DatacenterRepresenter
end
