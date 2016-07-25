class Tag < ActiveRecord::Base
  has_many :taggings
  
  with_options through: :taggings, source: :taggable, dependent: :destroy do |tag|
    tag.has_many :users, :source_type => 'User'
    tag.has_many :servers, :source_type => 'Server'
  end

  
  scope :unscoped_for, -> (asset) { joins(:taggings).where(taggings: {taggable_type: "#{asset.to_s.capitalize}"}).distinct }
  
  scope :for, -> (asset) { joins(asset.to_s.downcase.pluralize.to_sym).distinct }
    
  # make sure bindings (taggings) are properly updated
  def delete
    destroy
  end
  
  def to_s
    label
  end
end
