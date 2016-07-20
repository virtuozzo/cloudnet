class AutoTags
  AVAILABLE_TAGS = %i(shrinking growing stable)
  
  def self.check_auto_tags_ready
    AVAILABLE_TAGS.each { |label| Tag.find_or_create_by label: label }
  end
end