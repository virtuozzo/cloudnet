require 'active_support/concern'

class Account < ActiveRecord::Base
  module Account::Wallet
    extend ActiveSupport::Concern

    # Leaving this here for Unbilled revenue calculation on admin dashboard, which should be zero from now on anyway
    def used_payg_balance
      date_range = past_invoice_date..next_invoice_date
      transactions = server_hourly_transactions.with_deleted.where(created_at: date_range).without_duplicates.billable
      transactions.to_a.sum(&:cost)
    end

    # Sum of Invoice balances
    def remaining_invoice_balance
      invoices.includes(:invoice_items, :charges, :coupon).to_a.sum(&:remaining_cost)
    end

    # Sum of Credit notes
    def remaining_credit_balance
      credit_notes.includes(:credit_note_items, :coupon).to_a.sum(&:remaining_cost)
    end

    # Sum of Payment receipts
    def payment_receipts_balance
      payment_receipts.to_a.sum(&:remaining_cost)
    end
    
    # Sum of Payment receipts and Credit notes
    def wallet_balance
      payment_receipts_balance + remaining_credit_balance
    end

    # Actual balance after unpaid invoices
    def remaining_balance
      remaining_invoice_balance - wallet_balance
    end
    
    # Return number of days worth available on Wallet
    def wallet_server_days(server)
      hourly_cost = server.hourly_cost
      ((remaining_balance * -1).to_f / hourly_cost.to_f) / 24.0
    end
    
    def expire_wallet_balance
      Rails.cache.delete(['remaining_balance', user.id])
    end
  end
end
