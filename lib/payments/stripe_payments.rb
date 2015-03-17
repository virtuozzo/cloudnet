require 'stripe'

Stripe.api_key = PAYMENTS[:stripe][:api_key]

class StripePayments < Payments::Methods
  def create_customer(user)
    customer = Stripe::Customer.create(description: "User ID: #{user.id}", email: user.email)
    customer.id
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
        country: charge.card.country
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
        country: charge.card.country
      },
      captured: charge.captured
    }
  end
end
