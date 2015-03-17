json.extract! card, :id, :last4, :expiry_month, :expiry_year, :card_type, :cardholder, :created_at, :updated_at

if card.fraud_assessment[:assessment] != :safe
  json.requires_validation 1
else
  json.requires_validation 0
end

if primary_card.present?
  json.primary primary_card.id == card.id
else
  json.primary 0
end
