## Converts all PAYG servers to Prepaid servers
## Gets all PAYG servers and generates an invoice from last invoice date to current date using
## server hourly transactions. Then generates a Prepaid invoice from current date to next
## invoice date.

class ConvertPaygToPrepaid
  def self.run
    new.run
  end

  def run
    Account.find_each do |account|
      user    = account.user
      # Get user's existing PAYG servers
      existing_servers = user.servers.payg
      # Get deleted PAYG servers deleted after last invoice date time
      deleted_servers = user.servers.only_deleted.payg
                        .where('deleted_at > ?', account.past_invoice_due)
      all_payg_servers = existing_servers + deleted_servers
      
      begin
        # Generate PAYG invoice using server transactions from last invoice date to current date time
        FinalPaygBillingTask.new(user, all_payg_servers).process unless all_payg_servers.empty?
        
        # Convert existing servers to prepaid
        existing_servers.each do |server|
          server.update_attribute :payment_type, :prepaid
        end
        
        # Generate Prepaid invoice until next invoice date for existing servers
        AutomatedBillingTask.new(user, existing_servers).process unless existing_servers.empty?
        
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'FinalPaygBilling' })
      end
    end
  end
end
