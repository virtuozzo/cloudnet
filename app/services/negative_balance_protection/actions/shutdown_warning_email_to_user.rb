module NegativeBalanceProtection
  module Actions
    class DestroyWarningEmailToUser
      attr_reader :user
      
      def initialize(user)
        @user = user
      end
      
      def perform
        NegativeBalanceMailer.destroy_warning_email_to_user(user).deliver_now
      end
    end
  end
end