require 'rails_helper'

describe 'Negative balance mailer', type: :mailer do
  xit 'sends a mail when balance is negative' do
    user = FactoryGirl.create :user
    invoice = FactoryGirl.create :invoice
    item1 = FactoryGirl.create(:invoice_item, invoice: invoice, net_cost: 100_000)
    item2 = FactoryGirl.create(:invoice_item, invoice: invoice, net_cost: 34_000)
    invoice.invoice_items << [item1, item2]
    user.account = invoice.account
    user.save

    NegativeBalanceChecker.perform_async
    NegativeBalanceChecker.drain

    deliveries = ActionMailer::Base.deliveries
    warning_emails = deliveries.select { |m| m.subject[/negative balance warning/] }
    expect(warning_emails.length).to eq 1
    email = warning_emails.first
    expect(email.bcc).to eq ENV['MAILER_ENQUIRY_RECIPIENTS'].split(', ')
    negative_balance = Regexp.escape Invoice.pretty_total user.account.remaining_balance
    expect(email.body.to_s).to match(/account balance is currently negative by #{negative_balance}/)
  end
end
