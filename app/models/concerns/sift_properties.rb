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

  def sift_invoice_properties
    user = account.user
    properties = user.sift_user_properties.except! :$name
    invoice_properties = {
      "$order_id": id,
      "$amount": total_cost * Invoice::MICROS_IN_MILLICENT,
      "$currency_code": "USD",
      "digital_wallet": "cloudnet_wallet",
      "is_first_time_buyer": (user.servers.with_deleted.count == 1),
      "$shipping_method": "$electronic"
    }
    properties.merge! invoice_properties
    properties.merge! "coupon_code": coupon.coupon_code if coupon
    properties.merge! "$items": sift_invoice_items_properties
    # properties.merge! "$seller_user_id": location.id
  rescue StandardError
    nil
  end

  def sift_invoice_items_properties
    invoice_items.map { |item|
      if item.source_type == 'Server'
        server = Server.with_deleted.find item.source_id
        provider = "#{server.location.provider} #{server.location.city}"
        item.description += " @ #{provider}"
      end

      properties = {
        "$item_id": item.source_id,
        "$product_title": item.description,
        "$category": item.source_type,
        "$price": item.total_cost * Invoice::MICROS_IN_MILLICENT,
        "$quantity": 1
      }
      properties.merge!("city": server.location.city, "$brand": server.location.provider) if server
    }
  rescue StandardError
    nil
  end

end
