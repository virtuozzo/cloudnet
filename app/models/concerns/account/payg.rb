require 'active_support/concern'

class Account < ActiveRecord::Base
  module Account::Payg
    extend ActiveSupport::Concern

    def used_payg_balance
      date_range = past_invoice_date..next_invoice_date
      transactions = server_hourly_transactions.with_deleted.where(created_at: date_range).without_duplicates.billable
      transactions.to_a.sum(&:cost)
    end

    def available_payg_balance
      payg_balance - used_payg_balance
    end

    def payg_balance
      payment_receipts.to_a.sum(&:remaining_cost)
    end
    
    def available_wallet_balance
      available_payg_balance + remaining_balance.abs
    end

    def payg_server_days(server)
      hourly_cost = server.hourly_cost
      (available_payg_balance.to_f / hourly_cost.to_f) / 24.0
    end
    
    # Return number of days worth available on Wallet (which is PAYG balance + credit notes)
    def wallet_server_days(server)
      hourly_cost = server.hourly_cost
      (available_wallet_balance.to_f / hourly_cost.to_f) / 24.0
    end
  end
end
