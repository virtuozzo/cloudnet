require 'rails_helper'

describe BillingCard do
  let(:card) { FactoryGirl.create(:billing_card) }
  let(:user) { FactoryGirl.create(:user) }

  it 'should be a valid billing card' do
    expect(card).to be_valid
  end

  it 'should be invalid without an account' do
    card.account = nil
    expect(card).not_to be_valid
  end
  
  it 'should be invalid without phone verification' do
    user.phone_number = nil
    new_card = FactoryGirl.build(:billing_card, account: user.account)
    expect(user.phone_verified?).to be false
    expect(new_card).not_to be_valid
  end

  describe 'Country and Country Codes' do
    it 'should be invalid without a country' do
      card.country = ''
      expect(card).not_to be_valid
    end

    it 'should be valid with a proper country code' do
      card.country = 'GB'
      expect(card).to be_valid
    end

    it 'should be invalid without a proper country code' do
      card.country = 'QU'
      expect(card).not_to be_valid
    end
  end

  it 'should be invalid without a city' do
    card.city = ''
    expect(card).not_to be_valid
  end

  it 'should be invalid without a region' do
    card.region = ''
    expect(card).not_to be_valid
  end

  it 'should be invalid without a postal code' do
    card.postal = ''
    expect(card).not_to be_valid
  end

  it 'should be invalid without card details' do
    [:bin=, :expiry_month=, :expiry_year=, :cardholder=, :last4=].each do |a|
      card = FactoryGirl.create(:billing_card)
      card.send(a, '')
      expect(card).not_to be_valid
    end
  end

  it 'should only accept valid expiry months' do
    card.expiry_month = '01'
    expect(card).to be_valid
    card.expiry_month = '09'
    expect(card).to be_valid
    card.expiry_month = '12'
    expect(card).to be_valid

    card.expiry_month = '13'
    expect(card).not_to be_valid
    card.expiry_month = '00'
    expect(card).not_to be_valid
    card.expiry_month = '120'
    expect(card).not_to be_valid
  end

  it 'should only accept valid expiry years' do
    card.expiry_year = '14'
    expect(card).to be_valid
    card.expiry_year = '19'
    expect(card).to be_valid
    card.expiry_year = '25'
    expect(card).to be_valid

    card.expiry_year = '30'
    expect(card).not_to be_valid
    card.expiry_year = '13'
    expect(card).not_to be_valid
    card.expiry_year = '001'
    expect(card).not_to be_valid
    card.expiry_year = '290'
    expect(card).not_to be_valid
  end

  it 'should only accept valid bin numbers 6 digits long' do
    card.bin = '142323'
    expect(card).to be_valid
    card.bin = '767423'
    expect(card).to be_valid
    card.bin = '423566'
    expect(card).to be_valid

    card.bin = '301'
    expect(card).not_to be_valid
    card.bin = '1322323'
    expect(card).not_to be_valid
  end

  it 'should only accept valid last4 numbers 4 digits long' do
    card.last4 = '1423'
    expect(card).to be_valid
    card.last4 = '7623'
    expect(card).to be_valid
    card.last4 = '4266'
    expect(card).to be_valid

    card.last4 = '301'
    expect(card).not_to be_valid
    card.last4 = '1322323'
    expect(card).not_to be_valid
  end

  it 'should be invalid without an IP address' do
    card.ip_address = ''
    expect(card).not_to be_valid
  end

  it 'should be invalid without a user agent' do
    card.user_agent = ''
    expect(card).not_to be_valid
  end

  it 'should only list processable if it has a payment token and fraud verified' do
    card1 = FactoryGirl.create(:billing_card, fraud_verified: true, processor_token: 'abcd1234')
    card2 = FactoryGirl.create(:billing_card, fraud_verified: true, processor_token: 'abcd1234')
    card3 = FactoryGirl.create(:billing_card)

    processable = BillingCard.all.processable
    expect(processable).to include(card1, card2)
    expect(processable).not_to include(card3)
  end

  describe 'Fraud Assessment' do
    it 'should return unassessed if not fraud verified by default' do
      expect(card.fraud_assessment).to eq({ assessment: :unassessed })
    end

    it 'should return safe if between 0 and 15' do
      card.fraud_verified = true
      card.fraud_score = 0.0
      expect(card.fraud_assessment).to eq({ assessment: :safe })
      card.fraud_score = 15.0
      expect(card.fraud_assessment).to eq({ assessment: :safe })
    end

    it 'should return verify if between 15 and 40' do
      card.fraud_verified = true
      card.fraud_score = 15.1
      expect(card.fraud_assessment).to eq({ assessment: :validate })
      card.fraud_score = 40.0
      expect(card.fraud_assessment).to eq({ assessment: :validate })
    end

    it 'should return rejected if 40+' do
      card.fraud_verified = true
      card.fraud_score = 40.1
      expect(card.fraud_assessment).to eq({ assessment: :rejected })
      card.fraud_score = 65.0
      expect(card.fraud_assessment).to eq({ assessment: :rejected })
    end

    it 'should return verify if not between the ranges' do
      card.fraud_verified = true
      card.fraud_score = -1.0
      expect(card.fraud_assessment).to eq({ assessment: :validate })
      card.fraud_score = 101.0
      expect(card.fraud_assessment).to eq({ assessment: :validate })
    end
  end

  describe 'primary card' do
    it 'should set a card to primary' do
      card.update(primary: false)
      expect(card.primary).to be false

      card.update(primary: true)
      expect(card.primary).to be true
    end

    it 'should unset a card to not primary if another primary card comes through' do
      card1 = FactoryGirl.create(:billing_card, account: user.account, primary: true)
      card2 = FactoryGirl.create(:billing_card, account: user.account)
      card3 = FactoryGirl.create(:billing_card, account: user.account)

      expect(card1.primary).to be true
      expect(card2.primary).to be false
      expect(card3.primary).to be false

      card3.update(primary: true)
      [card1, card2, card3].each(&:reload)

      expect(card1.primary).to be false
      expect(card2.primary).to be false
      expect(card3.primary).to be true
    end
    
    it 'should set a new primary card' do
      card1 = FactoryGirl.create(:billing_card, account: user.account, primary: true)
      card2 = FactoryGirl.create(:billing_card, account: user.account)
      
      expect(card1.primary).to be true
      expect(card2.primary).to be false
      
      card1.set_new_primary
      [card1, card2].each(&:reload)
      
      expect(card1.primary).to be false
      expect(card2.primary).to be true
    end
    
    it 'should not let delete the only card' do
      card1 = FactoryGirl.create(:billing_card, account: user.account)
      expect(card1.destroy).to be false
      
      card2 = FactoryGirl.create(:billing_card, account: user.account)
      expect(card1.destroy).to be card1
    end
  end
end
