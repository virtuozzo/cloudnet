require 'active_support/concern'

class User < ActiveRecord::Base
  module User::SiftUser
    extend ActiveSupport::Concern
  
    def sift_user
      @sift_user ||= SiftClientTasks.new.perform(:get_score, id.to_s)
    end
    
    def sift_score
      return nil if sift_user.nil?
      score = sift_user.body['score']
      (score * 100).round(1) unless score.nil?
    end
    
    def is_labelled_bad?
      return false if sift_user.nil?
      sift_user.body.has_key?('latest_label') ? sift_user.body['latest_label']['is_bad'].present? : false
    end
    
    def sift_actions
      return [] if sift_user.nil?
      actions = []
      sift_user.body["actions"].try(:each) do |action|
        trigger = action["triggers"].first
        actions << action["action"]["id"] if action["entity"]["id"] == id.to_s && trigger["type"] == "formula" && trigger["source"] == "score_api"
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
