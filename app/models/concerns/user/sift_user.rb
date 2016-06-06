require 'active_support/concern'

class User < ActiveRecord::Base
  module User::SiftUser
    extend ActiveSupport::Concern
  
    def sift_user
      @sift_user ||= begin
        properties = sift_user_properties.slice "$user_id", "$session_id"
        task = SiftClientTasks.new.perform(:create_event, "check_actions", properties, true)
        task.body['score_response'] if task
      end
    rescue StandardError
      nil
    end
    
    def sift_score
      return nil if sift_user.nil?
      score = sift_user['score']
      (score * 100).round(1) unless score.nil?
    end
    
    def is_labelled_bad?
      return false if sift_user.nil?
      sift_user.has_key?('latest_label') ? sift_user['latest_label']['is_bad'] : false
    end
    
    def sift_actions
      return [] if sift_user.nil?
      actions = []
      sift_user["actions"].try(:each) do |action|
        actions << action["action"]["id"] if action["entity"]["id"] == id.to_s
      end
      actions.uniq
    end
    
    def sift_valid?
      return true if sift_user.nil?
      if sift_actions.include? KEYS[:sift_science][:approve_action_id]
        true
      else
        !sift_actions.include? KEYS[:sift_science][:validate_action_id]
      end
    end
    
  end
end
