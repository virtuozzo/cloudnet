require 'active_support/concern'

class User < ActiveRecord::Base
  module User::Limitable
    extend ActiveSupport::Concern

    included do
      after_initialize :set_limitable_attributes
    end

    def set_limitable_attributes
      multiplier = 10
      self.vm_max         = 6 * multiplier
      self.memory_max     = 1536 * multiplier
      self.cpu_max        = 3 * multiplier
      self.storage_max    = 30 * multiplier
      self.bandwidth_max  = 50 * multiplier
    end
  end
end
