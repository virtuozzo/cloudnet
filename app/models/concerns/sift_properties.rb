## Contains mappings to Sift science properties

require 'active_support/concern'

module SiftProperties
  extend ActiveSupport::Concern

  def sift_user_properties(include_time_ip = false)
    primary_card = account.primary_billing_card
    properties = {
      "$user_id"                      => id,
      "$session_id"                   => anonymous_id,
      "$user_email"                   => email,
      "$name"                         => full_name,
      "$phone"                        => phone_number_full,
      "account_balance_amount"        => (account.reload.wallet_balance * Invoice::MICROS_IN_MILLICENT).to_i,
      "account_balance_currency_code" => "USD",
      "minfraud_score"                => account.max_minfraud_score,
      "risky_card_attempts"           => account.risky_card_attempts,
      "is_admin"                      => admin,
      "suspended"                     => suspended,
      "phone_verified"                => phone_verified?,
      "whitelisted"                   => whitelisted?
    }
    time_ip = {
      "$time"                         => created_at.to_i,
      "$ip"                           => current_sign_in_ip || last_sign_in_ip
    }
    properties.merge! time_ip if include_time_ip
    cards = account.billing_cards.processable.map { |card| card.sift_billing_card_properties }
    cards.push "$payment_type" => "$store_credit"
    properties.merge! "$payment_methods" => cards
    properties.merge! "$billing_address" => primary_card.sift_billing_address_properties unless primary_card.nil?
    properties.merge! "email_confirmed_status" => (confirmed? ? "$confirmed" : "$pending")
    properties.merge! "tags" => tag_labels.join(', ')
  rescue StandardError
    nil
  end
  
  def sift_billing_card_properties
    { 
      "$payment_type"     => "$credit_card",
      "$payment_gateway"  => "$stripe",
      "$card_bin"         => bin,
      "$card_last4"       => last4
    }
  rescue StandardError
    nil
  end
  
  def sift_billing_address_properties
    {
      "$name"       => cardholder,
      "$address_1"  => address1,
      "$address_2"  => address2,
      "$city"       => city,
      "$region"     => region,
      "$country"    => country,
      "$zipcode"    => postal
    }
  rescue StandardError
    nil
  end
  
  def sift_server_properties
    invoice_item = last_generated_invoice_item
    properties = user.sift_user_properties.except! "$name", "$payment_methods", "$billing_address", "$phone"
    server_properties = {
      "server_id"           => id,
      "primary_ip_address"  => primary_ip_address
    }
    properties.merge! server_properties
    unless invoice_item.nil?
      invoice_properties = {
        "invoice_id"          => invoice_item.invoice_id,
        "invoice_number"      => invoice_item.invoice.invoice_number
      }
      properties.merge! invoice_properties
    end
    # properties.merge! "$items" => sift_server_items_properties(invoice_item)
    properties
  rescue StandardError
    nil
  end
  
  def sift_server_items_properties(invoice_item)
    invoice_item.metadata.map { |item|
      properties = {
        "$product_title"  => item[:name],
        "$price"          => (item[:unit_cost].to_f * item[:units].to_f * Invoice::MICROS_IN_MILLICENT).to_i,
        "$quantity"       => item[:hours].to_f
      }
    }
  rescue StandardError
    nil
  end

  def sift_invoice_properties
    user = account.user
    properties = user.sift_user_properties.except! "$name", "$payment_methods", "$phone"
    invoice_properties = {
      "$order_id"           => id,
      "$amount"             => (total_cost * Invoice::MICROS_IN_MILLICENT).to_i,
      "$currency_code"      => "USD",
      "is_first_time_buyer" => (user.servers.with_deleted.count == 1),
      "$shipping_method"    => "$electronic",
      "invoice_number"      => invoice_number,
      "$payment_methods"    => [{"$payment_type" => "$store_credit"}],
      "$time"               => created_at.to_i
    }
    properties.merge! invoice_properties
    properties.merge! "coupon_code" => coupon.coupon_code if coupon
    properties.merge! "$items" => sift_invoice_items_properties
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
        "$item_id"        => item.source_id,
        "$product_title"  => item.description,
        "$category"       => item.source_type,
        "$price"          => (item.total_cost * Invoice::MICROS_IN_MILLICENT).to_i,
        "$quantity"       => 1
      }
      properties.merge!("city" => server.location.city, "$brand" => server.location.provider) if server
      properties
    }
  rescue StandardError
    nil
  end
  
  def sift_payment_receipt_properties(payment_properties = nil)
    properties = account.user.sift_user_properties.except! "$name", "$payment_methods", "$phone"
    pr_properties = {
      "$amount"                     => (net_cost * Invoice::MICROS_IN_MILLICENT).to_i,
      "$currency_code"              => "USD",
      "$transaction_type"           => "$deposit",
      "$transaction_status"         => "$success",
      "$transaction_id"             => number,
      "payment_processor_reference" => reference,
      "$time"                       => created_at.to_i
    }
    if payment_properties.nil?
      if pay_source == :billing_card
        if !billing_card.nil?
          payment_properties = billing_card.sift_billing_card_properties
        else
          payment_properties = { 
            "$payment_type"     => "$credit_card",
            "$payment_gateway"  => "$stripe"
          }
        end        
        success_properties = SiftProperties.stripe_success_properties(metadata)
        payment_properties.merge! success_properties unless success_properties.nil?
      elsif pay_source == :paypal
        payment_properties = SiftProperties.paypal_success_properties
      end
    end
    properties.merge! "$payment_method" => payment_properties if payment_properties
    properties.merge! pr_properties
  rescue StandardError
    nil
  end
  
  def sift_charge_properties
    if account.nil?
      properties = Hash.new
    else
      properties = account.user.sift_user_properties.except! "$name", "$payment_methods", "$phone"
    end
    ch_properties = {
      "$amount"             => (amount * Invoice::MICROS_IN_MILLICENT).to_i,
      "$currency_code"      => "USD",
      "$transaction_type"   => "$withdrawal",
      "$transaction_status" => "$success",
      "$transaction_id"     => number,
      "$order_id"           => invoice_id,
      "$payment_method"     => {"$payment_type" => "$store_credit"},
      "charge_source"       => source.number,
      "$time"               => created_at.to_i
    }
    properties.merge! ch_properties
  rescue StandardError
    nil
  end
  
  def sift_credit_note_properties
    properties = account.user.sift_user_properties.except! "$name", "$payment_methods", "$phone"
    transaction_type = (manually_added? || trial_credit?) ? "$deposit" : "$refund"
    invoice_id = credit_note_items.first.source.try(:last_generated_invoice_item).try(:invoice_id)
    cr_properties = {
      "$amount"             => (total_cost * Invoice::MICROS_IN_MILLICENT).to_i,
      "$currency_code"      => "USD",
      "$transaction_type"   => transaction_type,
      "$transaction_status" => "$success",
      "$transaction_id"     => number,
      "$order_id"           => invoice_id,
      "$payment_method"     => {"$payment_type" => "$store_credit"},
      "$time"               => created_at.to_i
    }
    properties.merge! cr_properties
  rescue StandardError
    nil
  end
  
  def self.stripe_success_properties(charge)
    {
      "$stripe_cvc_check"           => charge[:card][:cvc_check],
      "$stripe_address_line1_check" => charge[:card][:address_line1_check],
      "$stripe_address_zip_check"   => charge[:card][:address_zip_check],
      "$stripe_funding"             => charge[:card][:funding],
      "$stripe_brand"               => charge[:card][:brand]
    }
  rescue StandardError
    nil
  end
  
  def self.stripe_failure_properties(account, net_cost, error, payment_properties)
    properties = account.user.sift_user_properties.except! "$name", "$payment_methods", "$phone"
    pr_properties = {
      "$amount"                     => (net_cost * Invoice::MICROS_IN_MILLICENT).to_i,
      "$currency_code"              => "USD",
      "$transaction_type"           => "$deposit",
      "$transaction_status"         => "$failure",
      "payment_processor_reference" => error[:charge]
    }
    properties.merge! "$payment_method" => payment_properties if payment_properties
    properties.merge! pr_properties
  rescue StandardError
    nil
  end
  
  def self.paypal_properties(request = nil)
    properties = {
      "$payment_type"           => "$third_party_processor",
      "$payment_gateway"        => "$paypal"
    }
    request_properties = {
      "$paypal_payer_id"        => request.payer.identifier,
      "$paypal_payer_email"     => request.payer.email,
      "$paypal_payer_status"    => request.payer.status,
      "$paypal_address_status"  => request.address_status
    } if request
    properties.merge! request_properties if request_properties
    properties
  rescue StandardError
    nil
  end
  
  def self.paypal_success_properties(request = nil, response = nil)
    paypal_props = paypal_properties(request)
    response_properties = {
      "$paypal_protection_eligibility"  => response.payment_info.first.protection_eligibility,
      "$paypal_payment_status"          => response.payment_info.first.payment_status
    } if response
    paypal_props.merge! response_properties if response_properties
    paypal_props
  rescue StandardError
    nil
  end
  
  def self.paypal_failure_properties(account, request)
    properties = account.user.sift_user_properties.except! "$name", "$payment_methods", "$phone"
    pr_properties = {
      "$amount"                     => (request.amount.total.to_f * Invoice::MILLICENTS_IN_DOLLAR * Invoice::MICROS_IN_MILLICENT).to_i,
      "$currency_code"              => "USD",
      "$transaction_type"           => "$deposit",
      "$transaction_status"         => "$failure",
      "payment_processor_reference" => request.token
    }
    properties.merge! "$payment_method" => paypal_properties(request)
    properties.merge! pr_properties
  rescue StandardError
    nil
  end
  
  def self.sift_label_properties(is_bad, reasons, description = nil, source = nil, analyst = nil)
    args = method(__method__).parameters.map { |arg| arg[1] }
    args.map {|arg| ["$#{arg.to_s}", eval(arg.to_s)] }.to_h
  rescue StandardError
    nil
  end

end
