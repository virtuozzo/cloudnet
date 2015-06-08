require 'active_support/concern'

module CreditPaymentsShared
  extend ActiveSupport::Concern

  def remaining_cost
    read_attribute(:remaining_cost) || total_cost
  end

  def has_remaining_cost?
    remaining_cost > 0
  end

  def deduct_remaining_cost(balance)
    success = true
    transaction do
      success = false && break if remaining_cost <= 0 || balance > remaining_cost
      success = update(remaining_cost: remaining_cost - balance)
    end
    success
  end

  def add_remaining_cost(cost)
    success = true
    transaction do
      success = update!(remaining_cost: remaining_cost + cost)
    end
  end

  module ClassMethods
    def with_remaining_cost
      where('remaining_cost IS NULL OR remaining_cost > 0')
        .order('created_at ASC')
        .select(&:has_remaining_cost?)
    end

    # Use up the credit from unused/partially used credit notes
    def charge_account(notes, amount)
      remaining_charge = amount
      notes_used     = {}

      notes.each do |note|
        break if remaining_charge <= 0
        next unless note.has_remaining_cost?

        remaining_cost = note.remaining_cost
        deductable = if remaining_cost >= remaining_charge then remaining_charge else remaining_cost end
        if note.deduct_remaining_cost(deductable)
          notes_used[note.id] = deductable
          remaining_charge   -= deductable
        end
      end

      notes_used
    end

    def refund_used_notes(notes)
      notes.each do |k, v|
        credit_note = find(k)
        credit_note.add_remaining_cost(v)
      end
    end
  end
end
