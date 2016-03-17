require 'rails_helper'

describe ConvertPaygToPrepaid do
  it 'should convert PAYG server to Prepaid' do
    user = FactoryGirl.create(:user_onapp)
    account = FactoryGirl.create(:account, invoice_day: 1)
    payg_server = FactoryGirl.create(:server, :payg, user: user, created_at: Time.zone.now.change(day: 12))
    allow_any_instance_of(ChargeInvoicesTask).to receive(:unblock_servers)
    allow(RefreshServerUsages).to receive(:new).and_return(double('RefreshServerUsages', refresh_server_usages: true))

    Timecop.freeze Time.zone.now.change(day: 15) do
      ConvertPaygToPrepaid.run
    end
    
    payg_server.reload
    expect(payg_server.payment_type).to eq(:prepaid)    
    expect(user.account.invoices.size).to eq(2)
  end
end
