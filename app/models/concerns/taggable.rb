module Taggable
  extend ActiveSupport::Concern
  
  included do
    has_many :taggings, as: :taggable
    has_many :tags, through: :taggings
  end
  
  def tag_names
    tags.map(&:name)
  end
  
  def add_tag(agile_crm: true)
    
  end
end