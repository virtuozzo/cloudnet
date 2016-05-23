require 'rails_helper'

describe Billing::BillingBandwidth do

  let(:server) { FactoryGirl.create(:server, bandwidth: 100, free_billing_bandwidth: 100) }
  subject { Billing::BillingBandwidth.new(server) }
  before(:each) { Account.where(user_id: server.user_id).first.update(invoice_day: 17) }
  
  describe 'With no last invoice item' do
    let(:zero_resp) {{:billable=>0, :free=>0, :hours=>0}}
    
    it "returns zero-hash if previous invoice cannot be found" do
      expect(subject.bandwidth_usage).to eq(zero_resp)
    end
  
    it "returns 0 for hours_coefficient if last invoice cannot be found" do
      expect(subject.hours_used_coefficient).to eq 0
    end
  end
  
  describe 'With last invoice item existing' do
    let(:time) { Time.utc(2016,3,2,15,44) }
    let(:earlier) { time - 1.hour }
    let!(:invoice_item1) { FactoryGirl.create(:invoice_item, source: server, created_at: time, updated_at: time) }
    let!(:invoice_item2) { FactoryGirl.create(:invoice_item, source: server, created_at: earlier, updated_at: earlier) }
    
    after(:each) { Timecop.return }
    
    it 'returns last invoice item' do
      expect(subject.last_invoice).to eq invoice_item1
    end
    
    context 'Past Due Date' do
      it 'returns proper past due date' do
        due_date = Time.utc(2016,2,17,1,0)
        Timecop.freeze(time + 1.hour)
        expect(subject.last_due_date).to eq due_date
      end
      
      it 'returns past due date from previous billing month' do
        current_date = Time.utc(2016,3,17,2,34)
        due_date_past = Time.utc(2016,2,17,1,0)
        object = Billing::BillingBandwidth.new(server, :due_date)
        Timecop.freeze(current_date)
        expect(object.last_due_date).to eq due_date_past
      end
      
      it 'returns due date from this billing month' do
        current_date = Time.utc(2016,3,17,2,34)
        due_date_now = Time.utc(2016,3,17,1,0)
        object = Billing::BillingBandwidth.new(server, :destroy)
        Timecop.freeze(current_date)
        expect(object.last_due_date).to eq due_date_now
      end
    end
    
    it 'returns free bandwidth' do
      Timecop.freeze(time + 1.hour)
      expect(subject.free_bandwidth_since_last_due_date_MB).to eq 252
    end
    
    context 'Network Usage' do
      let!(:net_usage) { FactoryGirl.create(:network_server_usage, server: server) }
      let(:bw_hash) { {:billable=>1626, :free=>252, :hours=>352} }
      it 'returns calculated billable bandwidth' do
        Timecop.freeze(time + 1.hour)
        expect(subject.bandwidth_usage).to eq(bw_hash)
      end
    end
  end
end