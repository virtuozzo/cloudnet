require 'active_support/concern'

class User < ActiveRecord::Base
  module User::Limitable
    extend ActiveSupport::Concern

    included do
      after_initialize :set_limitable_attributes
    end

    private

    def set_limitable_attributes
      self.vm_max         ||= 2
      self.memory_max     ||= 1536
      self.cpu_max        ||= 3
      self.storage_max    ||= 30
      self.bandwidth_max  ||= 50
    end
  end
end
