require 'active_support/concern'

class ServerEvent < ActiveRecord::Base
  module ServerEvent::Status
    extend ActiveSupport::Concern

    def complete?
      status == 'complete'
    end

    def incomplete?
      !complete?
    end

    def failed?
      status == 'failed'
    end

    def running?
      status == 'running'
    end

    def cancelled?
      status == 'cancelled'
    end

    def finished?
      complete? || failed? || cancelled?
    end

    def pending?
      status == 'pending'
    end
  end
end
