require 'rails_helper'

describe AutoTopup do

  before :each do
    @user = FactoryGirl.create :user
    @account = @user.account
    @payments = double(Payments, auth_charge: { charge_id: 12_345 }, capture_charge: { charge_id: 12_345 })
    allow(Payments).to receive_messages(new: @payments)
  end

  it 'should topup Wallet' do
    allow_any_instance_of(Account).to receive(:fraud_safe?).and_return(true)
    credit_note = FactoryGirl.create :credit_note, account: @account
    FactoryGirl.create :credit_note_item, credit_note: credit_note, net_cost: 100_000
    FactoryGirl.create :server, user: @user
    FactoryGirl.create :billing_card, account: @account, fraud_verified: true
    expect(@account.reload.wallet_balance).to eq(100_000)

    AutoTopup.perform_async
    assert_equal 1, AutoTopup.jobs.size

    AutoTopup.drain
    @account.reload
    expect(@account.wallet_balance).to eq((Payg::MIN_AUTO_TOP_UP_AMOUNT * Invoice::MILLICENTS_IN_DOLLAR).to_i + 100_000)
  end

  it 'should not topup Wallet because account is not fraud safe' do
    allow_any_instance_of(Account).to receive(:fraud_safe?).and_return(false)
    credit_note = FactoryGirl.create :credit_note, account: @account
    FactoryGirl.create :credit_note_item, credit_note: credit_note, net_cost: 100_000
    FactoryGirl.create :server, user: @user
    FactoryGirl.create :billing_card, account: @account, fraud_verified: true
    expect(@account.reload.wallet_balance).to eq(100_000)

    AutoTopup.perform_async
    assert_equal 1, AutoTopup.jobs.size

    AutoTopup.drain
    @account.reload
    expect(@account.wallet_balance).to eq(100_000)
  end

  it 'shoul not topup Wallet because there are no active servers' do
    credit_note = FactoryGirl.create :credit_note, account: @account
    FactoryGirl.create :credit_note_item, credit_note: credit_note, net_cost: 100_000
    FactoryGirl.create :billing_card, account: @account, fraud_verified: true
    expect(@account.reload.wallet_balance).to eq(100_000)

    AutoTopup.perform_async
    assert_equal 1, AutoTopup.jobs.size

    AutoTopup.drain
    @account.reload
    expect(@account.wallet_balance).to eq(100_000)
  end

  it 'shoul not topup Wallet because there are no processable cards' do
    FactoryGirl.create :billing_card, account: @account, fraud_verified: false

    AutoTopup.perform_async
    assert_equal 1, AutoTopup.jobs.size

    AutoTopup.drain
    @account.reload
    expect(@account.wallet_balance).to eq(0)
  end

  it 'should not topup Wallet because there are enough Wallet balance' do
    credit_note = FactoryGirl.create :credit_note, account: @account
    FactoryGirl.create :credit_note_item, credit_note: credit_note, net_cost: 500_000
    FactoryGirl.create :server, user: @user
    FactoryGirl.create :billing_card, account: @account, fraud_verified: true
    expect(@account.reload.wallet_balance).to eq(500_000)

    AutoTopup.perform_async
    assert_equal 1, AutoTopup.jobs.size

    AutoTopup.drain
    @account.reload
    expect(@account.wallet_balance).to eq(500_000)
  end

  it 'should not topup Wallet because Auto top-up is not enabled' do
    @account.update(auto_topup: false)
    credit_note = FactoryGirl.create :credit_note, account: @account
    FactoryGirl.create :credit_note_item, credit_note: credit_note, net_cost: 100_000
    FactoryGirl.create :server, user: @user
    FactoryGirl.create :billing_card, account: @account, fraud_verified: true
    expect(@account.reload.wallet_balance).to eq(100_000)

    AutoTopup.perform_async
    assert_equal 1, AutoTopup.jobs.size

    AutoTopup.drain
    @account.reload
    expect(@account.wallet_balance).to eq(100_000)
  end

end
