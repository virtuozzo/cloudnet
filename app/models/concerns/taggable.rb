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
    added = labels.map do |label|
      next if current_labels.include? label.to_s
      tag = Tag.find_or_create_by label: label
      tags << tag
      tag.label
    end
    reload
    added.compact
  end

  # removes tags with given label binding from the model.
  # Tag object is not deleted
  def remove_tags_by_label(*labels)
    current_labels = tag_labels
    labels = labels.flatten.compact.uniq
    removed = labels.map do |label|
      next unless current_labels.include? label.to_s
      tag = Tag.find_by label: label
      remove_tagging(tag)
      tag.label
    end
    reload
    removed.compact
  end

  # adds or removes tags acoording to hash of labels
  # ex. secured: true, important: false - adds 'secured' tag and removes 'important' tag from resource
  def add_remove_tags_by_hash(label_hash)
    return false unless label_hash.is_a?(Hash) && label_hash.values.all? {|v| v.in? [true, false]}
    add_labels = label_hash.select {|k,v| v}.keys
    remove_labels = label_hash.select {|k,v| !v}.keys
    added = add_tags_by_label(add_labels)
    removed = remove_tags_by_label(remove_labels)
    [added: added, removed: removed]
  end
end