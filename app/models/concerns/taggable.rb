module Taggable
  extend ActiveSupport::Concern
  
  included do
    has_many :taggings, as: :taggable
    has_many :tags, through: :taggings
    accepts_nested_attributes_for :tags
  end
  
  def tag_labels
    tags.map(&:label)
  end

  # removes tag binding from object
  def remove_tagging(tag)
    tag.taggings.where(taggable: self).delete_all
  end
end