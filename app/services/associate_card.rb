class AssociateCard
  def initialize(card, token)
    @account = card.account
    @card = card
    @token = token
  end

  def process
    card = Payments.new.add_card(@account.gateway_id, @token)
    @card.update(processor_token: card[:card_id], card_type: card[:card_type])
  rescue Exception => e
    p e
    ErrorLogging.new.track_exception(e, extra: { source: 'AssociateCard', account: @account })
    @card.errors.add(:base, 'Could not associate card with account. Please try again later')
  end
end
