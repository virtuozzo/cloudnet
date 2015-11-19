module NegativeBalanceProtection
  module Actions
    class DestroyActionEmailToAdmin
      attr_reader :user
      
      def initialize(user)
        @user = user
      end
      
      def perform
        AdminMailer.destroy_action(user).deliver_now
      end
    end
  end
end
