module NegativeBalanceProtection
  module Actions
    class ShutdownWarningEmailToUser
      attr_reader :user
      
      def initialize(user)
        @user = user
      end
      
      def perform
        NegativeBalanceMailer.shutdown_warning_email_to_user(user).deliver_now
        create_activity
      end
      
      def create_activity
        user.create_activity(
          :shutdown_warning, 
          owner: user,
          params: { number: user.notif_delivered + 1 }
        )
      end
    end
  end
end