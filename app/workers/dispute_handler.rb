## Gets the list of disputes from Stripe which has been created in the last 24 hours. 
## Parses them to find the payment receipt and then the account associated with the charge.
## Shuts down all the servers in the account and blocks / places them under validation for admin to review.

class DisputeHandler
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    disputes = Payments.new.list_disputes (Time.zone.now - 1.day).beginning_of_day.to_i
    disputes.each do |dispute|
      begin
        # Process this dispute if it hasn't been already parsed before
        DisputeHandlerTask.new(dispute).process if dispute['metadata']['payment_receipt_id'].blank?
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { dispute: dispute["charge"], source: 'DisputeHandler' })
      end
    end
  end
end
