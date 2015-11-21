module NegativeBalanceProtection
  class Protector
    include ActionStrategies
    include Actions
    attr_reader :strategy, :user
    
    def self.fire_counter_actions(user, strategy = UserConstraintsAdminConfirm)
      new(user, strategy).counter_actions
    end
  
    def initialize(user, strategy)
      @user = user
      @strategy = strategy.new(user)
    end
  
    def counter_actions
      Rails.logger.info "actions: #{actions}"
      actions.each do |task|
        action = action(task)
        action.perform unless action.nil?
      end
      
      increment_notifications if increment_user_notifications?
      clear_notifications if clear_notifications?
      refresh_servers if servers_for_refresh?
    end
  
    def action(task)
      ("NegativeBalanceProtection::Actions::" + 
        task.to_s.camelize).constantize.new(user) 
    rescue 
      nil
    end
    
    def actions
      @actions ||= strategy.action_list
    end
    
    def increment_user_notifications?
      actions.present? && actions.include?(:increment_notifications_delivered)
    end
    
    def increment_notifications
      user.increment!(:notif_delivered)
    end
    
    def servers_for_refresh?
      actions.present? && 
      [
        :shutdown_all_servers, 
        :clear_notifications_delivered
      ].any? {|a| actions.include?(a)}
    end
    
    def refresh_servers
      user.refresh_my_servers
    end
    
    def clear_notifications?
      actions.present? && actions.include?(:clear_notifications_delivered)
    end
    
    def clear_notifications
      user.clear_unpaid_notifications
    end
  end
end