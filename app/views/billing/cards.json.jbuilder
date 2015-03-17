primary_card = @account.primary_billing_card

json.array! @cards do |card|
  json.partial! 'billing/card', card: card, primary_card: primary_card
end
