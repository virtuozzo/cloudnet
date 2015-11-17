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
      actions.each do |task|
        action = action(task)
        action.perform unless action.nil?
      end
      
      increment_notifications if increment_user_notifications?
      refresh_servers if servers_shut_down?
    end
  
    def action(task)
      ("Actions::"+task.to_s.camelize).constantize.new(user) rescue nil
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
    
    def servers_shut_down?
      actions.present? && actions.include?(:shutdown_all_servers)
    end
    
    def refresh_servers
      user.refresh_my_servers
    end
  end
end