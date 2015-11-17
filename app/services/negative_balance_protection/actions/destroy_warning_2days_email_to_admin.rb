module NegativeBalanceProtection
  module Actions
    class DestroyWarning2daysEmailToAdmin
      attr_reader :user
      
      def initialize(user)
        @user = user
      end
      
      def perform
        warn_admin_about_destroy if time_for_destroy_in(2)
      end
      
      def warn_admin_about_destroy
        AdminMailer.destroy_warning(user).deliver_now
      end
      
      def time_for_destroy_in(days)
        (user.notif_before_destroy - user.notif_delivered) <= days
      end
    end
  end
end