# Serialise datacentre objects
module DatacentreRepresenter
  include BaseRepresenter

  property :id
  property :created_at
  property :updated_at
  property :provider
  property :country
  property :city
  property :latitude
  property :longitude
  collection :templates, extend: TemplateRepresenter
end