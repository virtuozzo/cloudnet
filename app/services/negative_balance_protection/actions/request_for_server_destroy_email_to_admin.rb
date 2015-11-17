module NegativeBalanceProtection
  module Actions
    class RequestForServerDestroyEmailToAdmin
      REQUEST_NOT_SENT = 0
      REQUEST_SENT_NOT_CONFIRMED = 1
      REQUEST_SENT_CONFIRMED = 2
      
      attr_reader :user
      
      def initialize(user)
        @user = user
      end
      
      def perform
        AdminMailer.request_for_server_destroy(user).deliver_now
      end
    end
  end
end
