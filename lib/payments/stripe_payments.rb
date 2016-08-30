require 'stripe'

Stripe.api_key = PAYMENTS[:stripe][:api_key]
Stripe.api_version = PAYMENTS[:stripe][:api_version]

class StripePayments < Payments::Methods
  def create_customer(user)
    customer = Stripe::Customer.create(description: "User ID: #{user.id}", email: user.email)
    customer.id
  end
  
  def get_cards(user)
    customer = Stripe::Customer.retrieve(user.account.gateway_id)
    cards = customer["cards"]["data"].map { |d| d.to_json }
    cards.map { |d| JSON.parse d }
  end

  def add_card(cust_token, card_token)
    customer = Stripe::Customer.retrieve(cust_token)
    card = customer.cards.create(card: card_token)
    { card_id: card.id, card_type: card.brand.downcase, last4: card.last4 }
  end

  def remove_card(cust_token, card_token)
    customer = Stripe::Customer.retrieve(cust_token)
    customer.cards.retrieve(card: card_token).delete
  end

  def auth_charge(cust_token, card_token, amount)
    charge = Stripe::Charge.create(
      amount: amount,
      currency: 'usd',
      customer: cust_token,
      card: card_token,
      capture: false
    )

    {
      charge_id: charge.id,
      currency: charge.currency,
      amount: charge.amount,
      card: {
        id: charge.card.id,
        type: charge.card.brand,
        last4: charge.card.last4,
        customer: charge.card.customer,
        country: charge.card.country,
        cvc_check: charge.card.cvc_check,
        address_line1_check: charge.card.address_line1_check,
        address_zip_check: charge.card.address_zip_check,
        funding: charge.card.funding,
        brand: charge.card.brand
      },
      captured: charge.captured
    }
  end

  def capture_charge(charge_token, description)
    charge = Stripe::Charge.retrieve(charge_token)
    charge.description = description
    charge.capture

    {
      charge_id: charge.id,
      currency: charge.currency,
      amount: charge.amount,
      card: {
        id: charge.card.id,
        type: charge.card.brand,
        last4: charge.card.last4,
        customer: charge.card.customer,
        country: charge.card.country,
        cvc_check: charge.card.cvc_check,
        address_line1_check: charge.card.address_line1_check,
        address_zip_check: charge.card.address_zip_check,
        funding: charge.card.funding,
        brand: charge.card.brand
      },
      captured: charge.captured
    }
  end
  
  def list_disputes(created_after:, created_before: Time.zone.now.end_of_day.to_i, starting_after: nil, limit: 100, include_total: false)
    include_total = include_total ? ['total_count'] : nil
    Stripe::Dispute.all(created: {gte: created_after, lte: created_before}, include: include_total, limit: limit, starting_after: starting_after)
  end
  
  def get_dispute(dispute_id)
    Stripe::Dispute.retrieve(dispute_id)
  end
end
