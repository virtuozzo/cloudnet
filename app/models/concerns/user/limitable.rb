require 'active_support/concern'

class User < ActiveRecord::Base
  module User::Limitable
    NOTIF_BEFORE_DESTROY_DEFAULT = 7
    extend ActiveSupport::Concern

    included do
      before_create :set_limitable_attributes
    end

    def set_limitable_attributes
      multiplier = 3
      self.vm_max         = 1 * multiplier
      self.memory_max     = 1536 * multiplier
      self.cpu_max        = 3 * multiplier
      self.storage_max    = 50 * multiplier
      self.bandwidth_max  = 250 * multiplier
      self.notif_before_destroy = NOTIF_BEFORE_DESTROY_DEFAULT
    end
  end
end
