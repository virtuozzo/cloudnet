module NegativeBalanceProtection
  module ActionStrategies
    class BaseStrategy
      attr_reader :user
      MIN_HOURS_BETWEEN_EMAILS ||= 20

      def initialize(user)
        @user = user
      end

      #All tests must work independently and cannot overlap
      def action_list
        case
        when no_servers_or_positive_balance? then clear_notifications
        when before_shutdown_warnings? then before_shutdown_actions
        when perform_shutdown? then shutdown_servers_actions
        when before_destroy_warnings? then before_destroy_actions
        when perform_destroy? then destroy_servers_actions
        else no_actions
        end
      end


      # TRUE if number of emails sent to user is less than
      # defined in user profile for shutting down servers
      def shutdown_less_emails_sent_than_defined_in_user_profile?
        notifications_delivered < notifications_for_shutdown
      end

      # TRUE if number of emails sent to user is as
      # defined in user profile for shutting down servers
      def emails_sent_as_in_profile_for_shutdown?
        notifications_delivered == notifications_for_shutdown
      end

      # TRUE if number of emails sent to user is more than
      # defined in user profile for shutting down servers
      def shutdown_more_emails_sent_than_defined_in_user_profile?
        notifications_delivered > notifications_for_shutdown
      end

      # TRUE if number of emails sent to user is less than
      # defined in user profile for DESTROYING servers
      def destroy_less_emails_sent_than_defined_in_user_profile?
        notifications_delivered < notifications_for_destroy
      end

      def emails_sent_as_in_profile_for_destroy_or_more?
        notifications_delivered >= notifications_for_destroy
      end

      # TRUE if last, user warning email was sent in more than
      # MIN_HOURS_BETWEEN_EMAILS hours in the past
      def minimum_time_passed_since_last_warning_email?
        return true if user.last_notif_email_sent.nil?
        hours_since_last_email >= MIN_HOURS_BETWEEN_EMAILS
      end

      def no_servers_or_positive_balance?
        user.servers.empty? || positive_balance?
      end

      def positive_balance?
        account = Account.unscoped.where(deleted_at: nil, user_id: user.id).first
        account.remaining_balance < 100
      end

      def no_actions
        []
      end

      private
        def notifications_delivered
          user.notif_delivered
        end

        def notifications_for_shutdown
          user.notif_before_shutdown
        end

        def notifications_for_destroy
          user.notif_before_destroy
        end

        def hours_since_last_email
          ((Time.now - user.last_notif_email_sent) / 1.hour).floor
        end

        def before_shutdown_warnings?
          false
        end

        def perform_shutdown?
          false
        end

        def before_destroy_warnings?
          false
        end

        def perform_destroy?
          false
        end

        def clear_notifications
          [
            :clear_notifications_delivered
          ]
        end
    end
  end
end