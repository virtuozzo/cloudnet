require 'active_support/concern'

class User < ActiveRecord::Base
  module User::Limitable
    extend ActiveSupport::Concern

    included do
      before_create :set_limitable_attributes
    end

    def set_limitable_attributes
      multiplier = 1
      self.vm_max         = 2 * multiplier
      self.memory_max     = 1536 * multiplier
      self.cpu_max        = 3 * multiplier
      self.storage_max    = 50 * multiplier
      self.bandwidth_max  = 250 * multiplier
    end
  end
end
