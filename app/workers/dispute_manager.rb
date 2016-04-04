class DisputeManager
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    # TODO: Check time stamp correctly for duplicates
    disputes = Payments.new.list_disputes(Time.now.to_i - 1.day)
    return if disputes.blank?
    disputes = disputes["data"].map { |d| d.to_json }
    disputes = disputes.map { |d| JSON.parse d }
    return if disputes.size == 0
    disputes.each do |dispute|
      payment_receipt = PaymentReceipt.find_by_reference dispute["charge"]
      next if payment_receipt.blank?
      
      account = payment_receipt.account
      account.user.create_activity(:chargeback, owner: account.user, params: { amount: dispute['amount'], currency: dispute['currency'], reason: dispute['reason'], status: dispute['status'], payment_receipt_id: payment_receipt.id })
      
      account.user.servers.each do |server|
        # Shutdown and put the server under validation, eventually blocking the server on next refresh
        ServerTasks.new.perform(:shutdown, account.user_id, server.id)
        server.create_activity :shutdown, owner: server.user
        server.update!(validation_reason: 4)
        server.create_activity :validation, owner: server.user, params: { reason: server.validation_reason }
        
        # Notify customer and support
        NotifyUsersMailer.delay.notify_server_validation(server.user, server)
        SupportTasks.new.perform(:notify_server_validation, server.user, server) rescue nil        
        
        # Log the IP address used to add the credit cards in the account to risky ip addresses list for future use
        account.billing_cards.each do |card|
          RiskyIpAddress.create(ip_address: card.ip_address, account: account)
        end
      end
    end
  end  
end
