## Gets the list of disputes from Stripe which has been created in the last 24 hours. 
## Parses them to find the payment receipt and then the account associated with the charge.
## Shuts down all the servers in the account and blocks / places them under validation for admin to review.

class DisputeHandler
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    return unless PAYMENTS[:stripe][:api_key].present?
    disputes = []
    created_after = (Time.zone.now - 1.day).beginning_of_day.to_i
    starting_after = nil
    has_more = true
    
    while has_more
      disputes_raw = Payments.new.list_disputes created_after: created_after, starting_after: starting_after
      has_more = disputes_raw['has_more']
      disputes_raw['data'].map { |d| disputes.push(JSON.parse(d.to_json)) }
      starting_after = disputes.last['id'] unless disputes.empty?
    end
       
    disputes.each do |dispute|
      begin
        # Process this dispute if it hasn't been already parsed before
        DisputeHandlerTask.new(dispute).process if dispute['metadata']['payment_receipt_id'].blank?
      rescue StandardError => e
        ErrorLogging.new.track_exception(e, extra: { dispute: dispute["charge"], source: 'DisputeHandler' })
      end
    end
  end
end
