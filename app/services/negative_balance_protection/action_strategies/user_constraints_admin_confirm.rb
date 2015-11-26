module NegativeBalanceProtection
  module ActionStrategies
    class UserConstraintsAdminConfirm < BaseStrategy

      #Adding admin confirmation before destroying servers
      def action_list
        case
        when no_servers_or_positive_balance? then clear_notifications
        when admin_acknowledge_for_destroy? then admin_acknowledge_actions
        else super
        end
      end
      
      def before_shutdown_warnings?
        shutdown_less_emails_sent_than_defined_in_user_profile? &&
        minimum_time_passed_since_last_warning_email?
      end
      
      def before_shutdown_actions
        [
          :shutdown_warning_email_to_user,
          :increment_notifications_delivered
        ]
      end
      
      def perform_shutdown?
        emails_sent_as_in_profile_for_shutdown? &&
        minimum_time_passed_since_last_warning_email?
      end
      
      def shutdown_servers_actions
        [
          :shutdown_all_servers, 
          :shutdown_action_email_to_user, 
          :shutdown_action_email_to_admin,
          :increment_notifications_delivered
        ]
      end
      
      def before_destroy_warnings?
        shutdown_more_emails_sent_than_defined_in_user_profile? &&
        destroy_less_emails_sent_than_defined_in_user_profile? &&
        minimum_time_passed_since_last_warning_email?
      end
      
      def before_destroy_actions
        [
          :shutdown_all_servers, #in case of any servers started or created
          :destroy_warning_email_to_user, 
          :destroy_warning_2days_email_to_admin,
          :increment_notifications_delivered
        ]
      end
      
      def admin_acknowledge_for_destroy?
        request_for_server_destroy_email_not_sent? &&
        emails_sent_as_in_profile_for_destroy_or_more? &&
        minimum_time_passed_since_last_warning_email?
      end
      
      def admin_acknowledge_actions
        [
          :request_for_server_destroy_email_to_admin
        ]
      end
      
      def perform_destroy?
        emails_sent_as_in_profile_for_destroy_or_more? &&
        minimum_time_passed_since_last_warning_email? &&
        admin_approved?
      end
      
      def destroy_servers_actions
        [
          :destroy_all_servers_confirmed,
          :destroy_action_email_to_user,
          :destroy_action_email_to_admin,
          :clear_notifications_delivered
        ]
      end
      
      def request_for_server_destroy_email_not_sent?
        user.admin_destroy_request == Actions::RequestForServerDestroyEmailToAdmin::REQUEST_NOT_SENT
      end
      
      def admin_approved?
        user.admin_destroy_request == Actions::RequestForServerDestroyEmailToAdmin::REQUEST_SENT_CONFIRMED
      end
    end
  end
end