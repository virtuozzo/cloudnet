module NegativeBalanceProtection
  module Actions
    class RequestForServerDestroyEmailToAdmin
      REQUEST_NOT_SENT ||= 0
      REQUEST_SENT_NOT_CONFIRMED ||= 1
      REQUEST_SENT_CONFIRMED ||= 2

      attr_reader :user

      def initialize(user)
        @user = user
      end

      def perform
        send_email_to_admin
        set_email_sent_status
        create_activity
      end

      def send_email_to_admin
        AdminMailer.request_for_server_destroy(user).deliver_now
      end

      def set_email_sent_status
        user.update_attribute(:admin_destroy_request, REQUEST_SENT_NOT_CONFIRMED)
      end

      def create_activity
        user.create_activity(
          :request_for_server_destroy,
          owner: user
        )
      end
    end
  end
end
