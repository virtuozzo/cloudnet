module NegativeBalanceProtection
  module Actions
    class DestroyWarningEmailToUser
      attr_reader :user
      
      def initialize(user)
        @user = user
      end
      
      def perform
        NegativeBalanceMailer.destroy_warning_email_to_user(user).deliver_now
        create_activity
      end
      
      def create_activity
        user.create_activity(
          :destroy_warning, 
          owner: user,
          params: { number: user.notif_delivered + 1 }
        )
      end
    end
  end
end