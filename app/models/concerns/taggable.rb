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
    return 0 if tag.nil?
    tag.taggings.where(taggable: self).delete_all
  end
  
  # adds tags with given labels to a model. Tags created if necessary
  def add_tags_by_label(*labels)
    current_labels = tag_labels
    labels = labels.flatten.compact.uniq
    labels.each do |label|
      next if current_labels.include? label.to_s
      tag = Tag.find_or_create_by label: label
      tags << tag
    end
    reload
  end
  
  # removes tags with given label binding from the model.
  # Tag object is not deleted
  def remove_tags_by_label(*labels)
    current_labels = tag_labels
    labels = labels.flatten.compact.uniq
    labels.each do |label|
      next unless current_labels.include? label.to_s
      remove_tagging(Tag.find_by label: label)
    end
    reload
  end
end