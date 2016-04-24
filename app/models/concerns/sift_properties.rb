require 'active_support/concern'

module SiftProperties
  extend ActiveSupport::Concern

  def sift_user_properties
    primary_card = account.primary_billing_card

    properties = {
      "$user_id": id,
      "$session_id": anonymous_id,
      "$user_email": email,
      "$name": full_name
    }

    unless account.billing_cards.blank?
      # TODO: Log address line check and zip check from Stripe
      cards = account.billing_cards.map { |card|
          { "$payment_type": "$credit_card",
            "$payment_gateway": "$stripe",
            "$card_bin": card.bin,
            "$card_last4": card.last4
            # "$stripe_address_line1_check" => "pass",
            # "$stripe_address_line2_check" => "pass",
            # "$stripe_address_zip_check"   => "pass"
          }
        }
      properties.merge! "$payment_methods": cards
    end

    unless primary_card.nil?
      billing_address = {
        "$name": primary_card.cardholder,
        "$address_1": primary_card.address1,
        "$address_2": primary_card.address2,
        "$city": primary_card.city,
        "$region": primary_card.region,
        "$country": primary_card.country,
        "$zipcode": primary_card.postal
      }
      properties.merge! "$billing_address": billing_address
    end

    properties.merge! "email_confirmed_status": (confirmed? ? "$confirmed" : "$pending")
  rescue StandardError
    nil
  end

end
