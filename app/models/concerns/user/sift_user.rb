require 'active_support/concern'

class User < ActiveRecord::Base
  module User::SiftUser
    extend ActiveSupport::Concern
  
    def sift_user
      @sift_user ||= SiftTasks.new.perform(:get_score, id.to_s)
    end
    
    def sift_score
      (sift_user.body['score'] * 100).round(1)
    end
    
    def is_labelled_bad?
      sift_user.body.has_key?('latest_label') ? sift_user.body['latest_label']['is_bad'].present? : false
    end
    
    def sift_actions
      actions = []
      sift_user.body["actions"].try(:each) do |action|
        trigger = action["triggers"].first
        actions << action["action"]["id"] if action["entity"]["id"] == id.to_s && trigger["type"] == "formula" && trigger["source"] == "score_api"
      end
      actions
    end
    
    def sift_valid?
      return true if KEYS[:sift_science][:api_key].blank?
      if sift_actions.include? ENV['SIFT_USER_APPROVE_ACTION_ID']
        true
      else
        !sift_actions.include? ENV['SIFT_USER_VALIDATE_ACTION_ID']
      end
    end
    
  end
end
