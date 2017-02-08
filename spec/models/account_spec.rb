require 'rails_helper'

describe Account do
  let(:user) { FactoryGirl.create(:user) }

  it 'should be a valid account' do
    expect(user.account).to be_valid
  end

  it 'should not include suspended users in its default scope' do
    user.update! suspended: true
    expect(Account.count).to eq 0
  end

  describe 'Invoicing Start and Invoicing Day' do
    it 'should set an invoicing start and invoicing day' do
      expect(user.account.invoice_day).to be_present
      expect(user.account.invoice_start).to be_present
    end

    # Note: this spec failed on April 1st 2015, but only on Codeship's CI. Fixed it by hardcoding
    # the month in date.change() There was no obvious reason for the discrepancy
    it 'should set an invoicing day between 1 and 28 just fine' do
      date = Date.today
      [1, 3, 6, 10, 15, 23, 28].each do |number|
        date = date.change(month: 1, day: number, hour: 0)
        Timecop.freeze date do
          account = FactoryGirl.create(:user).account
          expect(account.invoice_day).to eq(number)
          expect(account.invoice_start).to eq(date)
        end
      end
    end

    it 'should move to the 1st of next month for 29, 30 and 31' do
      next_month = Date.today.change(month: 1).next_month.beginning_of_month

      (29..31).each do |number|
        Timecop.freeze Date.today.change(day: number, month: 1) do
          account = FactoryGirl.create(:user).account
          expect(account.invoice_day).to   eq(1)
          expect(account.invoice_start).to eq(next_month)
        end
      end
    end
  end

  it 'should generate a payment token for the account on create' do
    allow_any_instance_of(Payments.klass).to receive(:create_customer).and_return('cn_cba123456')
    account = FactoryGirl.create(:account, gateway_id: nil)
    expect(account.gateway_id).to eq('cn_cba123456')
  end

  describe 'Calculating invoice dates and hours' do
    describe 'Next invoice date' do
      it "should return today if invoice date is today and it's before 1am" do
        Timecop.freeze Time.now.change(day: 1, month: 1, hour: 0) do
          account = FactoryGirl.create(:account)
          expect(account.next_invoice_date).to eq(Time.now)
        end
      end

      it "should return next month if invoice date is today but it's after 1am" do
        Timecop.freeze Time.now.change(day: 1, month: 1, hour: 1) do
          account = FactoryGirl.create(:account)
          expect(account.next_invoice_date).to eq(Time.now + 1.month)
        end
      end

      it 'should return next month if invoice date has passed' do
        Timecop.freeze Time.now.change(day: 25, month: 1, hour: 1) do
          account = FactoryGirl.create(:account, invoice_day: 24)
          expect(account.next_invoice_date).to eq(Time.now.next_month.change(day: 24))
        end
      end

      it 'should return this month if invoice date has not passed' do
        Timecop.freeze Time.now.change(day: 25, month: 1, hour: 1) do
          account = FactoryGirl.create(:account, invoice_day: 26)
          expect(account.next_invoice_date).to eq(Time.now.change(day: 26))
        end
      end
    end

    describe 'Past invoice date' do
      it "should return past month if invoice date is today and it's before 1am" do
        Timecop.freeze Time.now.change(day: 1, month: 1, hour: 0) do
          account = FactoryGirl.create(:account)
          expect(account.past_invoice_date).to eq(Time.now.last_month)
        end
      end

      it "should return this month if invoice date is today but it's after 1am" do
        Timecop.freeze Time.now.change(day: 1, month: 1, hour: 1) do
          account = FactoryGirl.create(:account)
          expect(account.past_invoice_date).to eq(Time.now)
        end
      end

      it 'should return this month if invoice date has passed' do
        Timecop.freeze Time.now.change(day: 25, month: 1, hour: 1) do
          account = FactoryGirl.create(:account, invoice_day: 24)
          expect(account.past_invoice_date).to eq(Time.now.change(day: 24))
        end
      end

      it 'should return last month if invoice date has not passed' do
        Timecop.freeze Time.now.change(day: 25, month: 1, hour: 1) do
          account = FactoryGirl.create(:account, invoice_day: 26)
          expect(account.past_invoice_date).to eq(Time.now.last_month.change(day: 26))
        end
      end
    end

    it 'should give an invoice time of 1am UTC' do
      expect(user.account.next_invoice_due.strftime('%H:%M:%S')).to eq('01:00:00')
    end

    describe 'Number of hours till next invoice' do
      it 'should give us the ceiling number for hours left' do
        Timecop.freeze Time.zone.now.change(day: 25, month: 1, hour: 1, min: 15) do
          account = FactoryGirl.create(:account, invoice_day: 26)
          expect(account.hours_till_next_invoice).to eq(24)
        end
      end

      it "should give us the a number of hours if we've passed it" do
        Timecop.freeze Time.zone.now.change(day: 25, month: 1, hour: 1) do
          account = FactoryGirl.create(:account, invoice_day: 24)
          expect(account.hours_till_next_invoice).to eq(30 * 24)
        end
      end

      it "should give us at least 1 hour even if it's less than that left" do
        Timecop.freeze Time.zone.now.change(day: 25, month: 1, hour: 0, min: 15) do
          account = FactoryGirl.create(:account, invoice_day: 25)
          expect(account.hours_till_next_invoice(Time.zone.now, Time.zone.now)).to eq(1)
        end
      end

      it "should give us the ceiling if we've just passed invoice day and time" do
        Timecop.freeze Time.zone.now.change(day: 25, month: 1, hour: 1, min: 0, sec: 1) do
          account = FactoryGirl.create(:account, invoice_day: 25)
          expect(account.hours_till_next_invoice).to eq(31 * 24)
        end
      end
    end

    describe 'Number of hours since past invoice' do
      it "should give us the past date hours if the invoice day is today and it's before 1am" do
        Timecop.freeze Time.zone.now.change(day: 26, month: 2, hour: 0, min: 15) do
          account = FactoryGirl.create(:account, invoice_day: 26)
          expect(account.hours_since_past_invoice(Time.zone.now)).to eq(31 * 24)
        end
      end

      it 'should give us the past date hours if the invoice day has not passed' do
        Timecop.freeze Time.zone.now.change(day: 25, month: 2, hour: 1) do
          account = FactoryGirl.create(:account, invoice_day: 26)
          expect(account.hours_since_past_invoice).to eq(30 * 24)
        end
      end

      it "should give us 1 hour if invoice day is today but it's past 1am" do
        Timecop.freeze Time.zone.now.change(day: 25, month: 1, hour: 1, min: 0, sec: 3) do
          account = FactoryGirl.create(:account, invoice_day: 25)
          expect(account.hours_since_past_invoice).to eq(1)
        end
      end

      it "should give us today's hours if invoice day for this month has passed" do
        Timecop.freeze Time.zone.now.change(day: 25, month: 1, hour: 6, min: 0, sec: 0) do
          account = FactoryGirl.create(:account, invoice_day: 25)
          expect(account.hours_since_past_invoice).to eq(5)
        end
      end
    end
  end

  describe 'VAT Exception' do
    it 'should not allow VAT Exception if from the UK' do
      allow(user.account).to receive_messages(billing_country: 'GB')
      expect(user.account.vat_exempt?).to be false

      allow(user.account).to receive_messages(billing_country: 'GB', vat_number: 'ABCD1234')
      expect(user.account.vat_exempt?).to be false
    end

    it 'should not allow VAT Exception if from the EU without a VAT Number' do
      allow(user.account).to receive_messages(billing_country: 'DE', vat_number: '')
      expect(user.account.vat_exempt?).to be false

      allow(user.account).to receive_messages(billing_country: 'PL', vat_number: '')
      expect(user.account.vat_exempt?).to be false
    end

    it 'should allow VAT Exception if from the EU with a VAT Number' do
      allow(user.account).to receive_messages(billing_country: 'DE', vat_number: 'ABCD1234')
      expect(user.account.vat_exempt?).to be true

      allow(user.account).to receive_messages(billing_country: 'PL', vat_number: 'ABCD1234')
      expect(user.account.vat_exempt?).to be true
    end

    it 'should allow VAT Exception if not from the EU' do
      allow(user.account).to receive_messages(billing_country: 'US', vat_number: '')
      expect(user.account.vat_exempt?).to be true

      allow(user.account).to receive_messages(billing_country: 'US', vat_number: 'ABCD1234')
      expect(user.account.vat_exempt?).to be true
    end
  end

  describe 'Tax Codes' do
    it 'should have the GB Tax Code if from the GB' do
      allow(user.account).to receive_messages(billing_country: 'GB')
      expect(user.account.tax_code).to eq('GB-O-STD')

      allow(user.account).to receive_messages(billing_country: 'GB', vat_number: 'ABCD1234')
      expect(user.account.tax_code).to eq('GB-O-STD')
    end

    it 'should have the GB Tax code if from the EU without a VAT Number' do
      allow(user.account).to receive_messages(billing_country: 'DE', vat_number: '')
      expect(user.account.tax_code).to eq('GB-O-STD')

      allow(user.account).to receive_messages(billing_country: 'PL', vat_number: '')
      expect(user.account.tax_code).to eq('GB-O-STD')
    end

    it 'should have the EU Tax code if from the EU with a VAT Number' do
      allow(user.account).to receive_messages(billing_country: 'DE', vat_number: 'ABCD1234')
      expect(user.account.tax_code).to eq('GB-O-EUS')

      allow(user.account).to receive_messages(billing_country: 'PL', vat_number: 'ABCD1234')
      expect(user.account.tax_code).to eq('GB-O-EUS')
    end

    it 'should have a exempt tax code if not from the EU' do
      allow(user.account).to receive_messages(billing_country: 'US', vat_number: '')
      expect(user.account.tax_code).to eq('GB-O-EXM')

      allow(user.account).to receive_messages(billing_country: 'US', vat_number: 'ABCD1234')
      expect(user.account.tax_code).to eq('GB-O-EXM')
    end
  end

  describe 'Risky Card calculation' do
    it 'should decrease the risky cards allowed if I send a rejected report' do
      account = user.account
      expect { account.calculate_risky_card(:rejected) }.to change { account.risky_cards_remaining }.by(-1)
    end
  end

  describe 'Billing country and Billing address' do
    it 'should give a nil billing country and billing address if no primary card set' do
      expect(user.account.primary_billing_card).to be_nil
      expect(user.account.billing_country).to be_nil
      expect(user.account.billing_address).to be_nil
    end

    it 'should give the primary card billing country if primary card set' do
      card = FactoryGirl.create(:billing_card, account: user.account, fraud_verified: true)
      expect(user.account.billing_country).to eq(card.country)
    end

    it 'should give the primary card address if primary card set' do
      card = FactoryGirl.create(:billing_card, account: user.account, fraud_verified: true)
      address = user.account.billing_address
      expect(address[:address1]).to eq(card.address1)
      expect(address[:postal]).to eq(card.postal)
    end
  end

  describe 'Coupon codes' do
    it 'should return true if attempted to set a valid coupon code' do
      coupon = FactoryGirl.create(:coupon)
      expect(user.account.set_coupon_code(coupon.coupon_code)).to be true
    end

    it 'returns true if expiry coupon date is today' do
      coupon = FactoryGirl.create(:coupon, expiry_date: Date.today)
      expect(user.account.set_coupon_code(coupon.coupon_code)).to be true
    end
    
    it 'should return false if attempted to set an invalid coupon code' do
      coupon = FactoryGirl.create(:coupon)
      expect(user.account.set_coupon_code('NOTVALID')).to be false
    end

    it 'should allow setting of coupon if none has been activated before' do
      expect(user.account.coupon_activated_at).to be_nil
      expect(user.account.can_set_coupon_code?).to be true
    end

    it 'should allow setting of coupon if more than allowed time period' do
      Timecop.freeze Time.zone.now.change(day: 25, month: 1, year: 2014, hour: 1, min: 0, sec: 1) do
        user.account.coupon_activated_at = Time.zone.now - Account::COUPON_LIMIT_MONTHS - 1.second
        expect(user.account.can_set_coupon_code?).to be true
      end
    end

    it 'should not allow setting of coupon if less than allowed time period' do
      Timecop.freeze Time.now.change(day: 25, month: 1, year: 2014, hour: 1, min: 0, sec: 1) do
        user.account.coupon_activated_at = Time.now - Account::COUPON_LIMIT_MONTHS + 1.second
        expect(user.account.can_set_coupon_code?).to be false
      end
    end
    
    context 'expired coupon' do
      it 'does not set inactive coupon coupon' do
        coupon = FactoryGirl.create(:coupon, active: false)
        expect(user.account.set_coupon_code(coupon.coupon_code)).to be false
      end
      
      it 'does not set expired coupon coupon' do
        coupon = FactoryGirl.create(:coupon, expiry_date: Date.today - 1.day)
        expect(user.account.set_coupon_code(coupon.coupon_code)).to be false
      end
    end
  end
  
  describe 'Fraud validator' do
    before :each do
      allow_any_instance_of(Account).to receive(:card_fingerprints).and_return(['abcd12345'])
    end
    
    it 'should return minfraud as a reason for fraud validation' do
      card = FactoryGirl.create(:billing_card, account: user.account, fraud_verified: true, fraud_score: 100.0)
      expect(user.account.fraud_validation_reason('0.0.0.0')).to eq(1)
    end
    
    it 'should fraud validate all billing cards in account' do
      card_1 = FactoryGirl.create(:billing_card, account: user.account, fraud_verified: true, fraud_score: 10.0)
      card_2 = FactoryGirl.create(:billing_card, account: user.account, fraud_verified: true, fraud_score: 100.0)
      expect(user.account.fraud_validation_reason('0.0.0.0')).to eq(1)
    end
    
    it 'should approve if all cards are marked as fraud safe' do
      card_1 = FactoryGirl.create(:billing_card, account: user.account, fraud_verified: true, fraud_score: 100.0, fraud_safe: true)
      card_2 = FactoryGirl.create(:billing_card, account: user.account, fraud_verified: true, fraud_score: 100.0, fraud_safe: true)
      expect(user.account.fraud_validation_reason('0.0.0.0')).to eq(0)
    end
    
    it 'should return IP history as a reason for fraud validation' do
      RiskyIpAddress.create(ip_address: '0.0.0.0', account: user.account)
      expect(user.account.fraud_validation_reason('0.0.0.0')).to eq(2)
    end
    
    it 'should return Card history as a reason for fraud validation' do
      RiskyCard.create(fingerprint: 'abcd12345', account: user.account)
      expect(user.account.fraud_validation_reason).to eq(5)
    end
    
    it 'should check IP history from billing cards for fraud validation' do
      RiskyIpAddress.create(ip_address: '0.0.0.0', account: user.account)
      card = FactoryGirl.create(:billing_card, account: user.account, fraud_verified: true, fraud_score: 10.0, ip_address: '0.0.0.0')
      expect(user.account.fraud_validation_reason('123.456.789.1')).to eq(2)
    end
    
    it 'should check login from risky IPs for fraud validation' do
      RiskyIpAddress.create(ip_address: '123.456.888.99', account: user.account)
      user.current_sign_in_ip, user.last_sign_in_ip = '123.456.888.99', '123.456.888.98'
      expect(user.account.fraud_validation_reason('123.456.888.99')).to eq(2)
    end
    
    it 'should return risky card attempts as a reason for fraud validation' do
      user.account.risky_cards_remaining = -1
      expect(user.account.fraud_validation_reason('0.0.0.0')).to eq(3)
    end
    
    it 'should allow only minimum wallet recharge for suspected fraud accounts' do
      card = FactoryGirl.create(:billing_card, account: user.account, fraud_verified: true, fraud_score: 100.0)
      expect(user.account.valid_top_up_amounts).to eq([Payg::VALID_TOP_UP_AMOUNTS.min])
    end
    
    it 'should approve if user is whitelisted' do
      user.account.update_attribute(:whitelisted, true)
      user.account.risky_cards_remaining = -1
      expect(user.account.fraud_validation_reason('0.0.0.0')).to eq(0)
    end
  end
  
  describe 'update forecasted revenue after coupon change' do
    it 'recalculates forecasted revenue after setting coupon code' do
      coupon = FactoryGirl.create(:coupon)
      user.servers << FactoryGirl.build(:server, memory: 512)
      user.servers << FactoryGirl.build(:server, memory: 1024)
      expect(user.forecasted_revenue).to eq 104899200
      user.account.set_coupon_code(coupon.coupon_code)
      expect(user.forecasted_revenue).to eq 83919360
    end
  end
end
