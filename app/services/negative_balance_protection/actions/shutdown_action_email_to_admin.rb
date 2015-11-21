module NegativeBalanceProtection
  module Actions
    class ShutdownActionEmailToAdmin
      attr_reader :user
      
      def initialize(user)
        @user = user
      end
      
      def perform
        AdminMailer.shutdown_action(user).deliver_now
      end
    end
  end
end