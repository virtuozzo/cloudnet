class Tag < ActiveRecord::Base
  has_many :taggings
  
  with_options through: :taggings, source: :taggable, dependent: :destroy do |tag|
    tag.has_many :users, :source_type => 'User'
    tag.has_many :servers, :source_type => 'Server'
  end
  
  # make sure bindings (taggings) are properly updated
  def delete
    destroy
  end
end
