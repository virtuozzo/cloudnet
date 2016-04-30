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
    cards = account.billing_cards.map { |card| card.sift_billing_card_properties }
    cards.push "$payment_type": "$store_credit"
    properties.merge! "$payment_methods": cards
    properties.merge! "$billing_address": primary_card.sift_billing_address_properties unless primary_card.nil?
    properties.merge! "email_confirmed_status": (confirmed? ? "$confirmed" : "$pending")
  rescue StandardError
    nil
  end
  
  # TODO: Log address line check and zip check from Stripe
  def sift_billing_card_properties
    { 
      "$payment_type": "$credit_card",
      "$payment_gateway": "$stripe",
      "$card_bin": bin,
      "$card_last4": last4
      # "$stripe_address_line1_check" => "pass",
      # "$stripe_address_line2_check" => "pass",
      # "$stripe_address_zip_check"   => "pass"
    }
  rescue StandardError
    nil
  end
  
  def sift_billing_address_properties
    {
      "$name": cardholder,
      "$address_1": address1,
      "$address_2": address2,
      "$city": city,
      "$region": region,
      "$country": country,
      "$zipcode": postal
    }
  rescue StandardError
    nil
  end
  
  def sift_server_properties
    account = user.account
    invoice_item = last_generated_invoice_item
    properties = user.sift_user_properties.except! :$name, :$payment_methods
    server_properties = {
      "$order_id": id,
      "$amount": invoice_item.invoice.total_cost * Invoice::MICROS_IN_MILLICENT,
      "$currency_code": "USD",
      "is_first_time_buyer": (user.servers.with_deleted.count == 1),
      "$shipping_method": "$electronic",
      "primary_ip_address": primary_ip_address,
      "invoice_id": invoice_item.invoice_id,
      "invoice_number": invoice_item.invoice.invoice_number
    }
    properties.merge! server_properties
    properties.merge! "coupon_code": user.account.coupon.coupon_code if user.account.coupon
    properties.merge! "$items": sift_server_items_properties(invoice_item)
  rescue StandardError
    nil
  end
  
  def sift_server_items_properties(invoice_item)
    invoice_item.metadata.map { |item|
      properties = {
        "$product_title": item[:name],
        "$price": item[:unit_cost].to_f * item[:units].to_f * Invoice::MICROS_IN_MILLICENT,
        "$quantity": item[:hours].to_f
      }
    }
  rescue StandardError
    nil
  end

  def sift_invoice_properties
    user = account.user
    properties = user.sift_user_properties.except! :$name, :$payment_methods
    invoice_properties = {
      "$order_id": id,
      "$amount": total_cost * Invoice::MICROS_IN_MILLICENT,
      "$currency_code": "USD",
      "is_first_time_buyer": (user.servers.with_deleted.count == 1),
      "$shipping_method": "$electronic",
      "invoice_number": invoice_number,
      "$payment_methods": [{"$payment_type": "$store_credit"}]
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
  
  def sift_payment_receipt_properties(payment_properties = nil)
    properties = account.user.sift_user_properties.except! :$name, :$payment_methods
    pr_properties = {
      "$amount": net_cost * Invoice::MICROS_IN_MILLICENT,
      "$currency_code": "USD",
      "$transaction_type": "$deposit",
      "$transaction_status": "$success",
      "$transaction_id": reference,
      "payment_receipt_number": receipt_number
    }
    properties.merge! "$payment_method": payment_properties if payment_properties
    properties.merge! pr_properties
  rescue StandardError
    nil
  end

end
