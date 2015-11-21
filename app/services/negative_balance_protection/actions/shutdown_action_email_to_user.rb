module NegativeBalanceProtection
  module Actions
    class ShutdownActionEmailToUser
      attr_reader :user
      
      def initialize(user)
        @user = user
      end
      
      def perform
        NegativeBalanceMailer.shutdown_action_email_to_user(user).deliver_now
      end
    end
  end
end