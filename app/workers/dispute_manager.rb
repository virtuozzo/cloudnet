## Gets the list of disputes from Stripe which has been created in the last 24 hours. 
## Parses them to find the payment receipt and then the account associated with the charge.
## Shuts down all the servers in the account and blocks / places them under validation for admin to review.

class DisputeManager
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    disputes = Payments.new.list_disputes (Time.now - 1.day).beginning_of_day.to_i
    return if disputes.blank?
    disputes = disputes["data"].map { |d| d.to_json }
    disputes = disputes.map { |d| JSON.parse d }
    return if disputes.size == 0
    disputes.each do |dispute|
      begin
        # Skip this dispute if it has been already parsed before
        next unless dispute['metadata']['account'].blank?
        
        payment_receipt = PaymentReceipt.find_by_reference dispute["charge"]
        next if payment_receipt.blank?
        
        account = payment_receipt.account
        account.user.create_activity(:chargeback, owner: account.user, params: { amount: dispute['amount'], currency: dispute['currency'], reason: dispute['reason'], status: dispute['status'], payment_receipt_id: payment_receipt.id })
        
        # Retrieve and update dispute object at Stripe with payment receipt and account info
        stripe_dispute = Stripe::Dispute.retrieve(dispute["id"])
        stripe_dispute.metadata = {payment_receipt_id: payment_receipt.id, payment_receipt_ref: payment_receipt.receipt_number, account: payment_receipt.account_id}
        stripe_dispute.save
        
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
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { dispute: dispute["charge"], source: 'DisputeManager' })
      end
    end
  end
end
