require 'active_support/concern'

module Metadata
  extend ActiveSupport::Concern

  def metadata=(metadata)
    data = if metadata.present? then metadata.to_json else nil end
    write_attribute(:metadata, data)
  end

  def metadata
    meta = read_attribute(:metadata)

    if meta.present?
      data = JSON.parse(meta)
      if data.is_a?(Array)
        return data.map(&:deep_symbolize_keys)
      elsif data.is_a?(Hash)
        return data.deep_symbolize_keys
      end
    else
      []
    end
  end
end
