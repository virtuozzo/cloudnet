class AssociateCard
  def initialize(card, token)
    @account = card.account
    @card = card
    @token = token
  end

  def process
    card = Payments.new.add_card(@account.gateway_id, @token)
    if @card.update(processor_token: card[:card_id], card_type: card[:card_type])
      CreditNote.trial_issue(@account, @card) if @account.fraud_safe? && @account.billing_cards.with_deleted.processable.count == 1
      true
    end
  rescue Exception => e
    p e
    ErrorLogging.new.track_exception(e, extra: { source: 'AssociateCard', account: @account })
    @card.errors.add(:base, 'Could not associate card with account. Please try again later')
  end
end
