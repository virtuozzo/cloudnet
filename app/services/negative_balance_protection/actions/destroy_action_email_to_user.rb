module NegativeBalanceProtection
  module Actions
    class DestroyActionEmailToUser
      attr_reader :user
      
      def initialize(user)
        @user = user
      end
      
      def perform
        NegativeBalanceMailer.destroy_action_email_to_user(user).deliver_now
      end
    end
  end
end