require 'rails_helper'

describe 'DNS', :vcr do
  include_context :with_user

  def create_dns_zone
    # Using build() to prevent user creation callbacks
    @domain = FactoryGirl.build(
      :dns_zone,
      domain: "cloudnetrspec2.com",
      user: @user
    )
    @onapp_domain = CreateDnsZone.new(@domain, @user).process
    @domain.domain_id = @onapp_domain['id']
  end

  it 'should create a DNS zone' do
    create_dns_zone
    expect(@onapp_domain['name']).to eq @domain.domain
  end

  xit 'should delete a DNS zone' do
  end

  xit 'should add records to a zone' do
  end

  xit 'should delete records from a zone' do
  end

  it 'should download the records of the zone' do
    create_dns_zone
    record = {
      dns_record: {
        ip: '1.2.3.4',
        name: 'rspec',
        type: 'a',
        ttl: 360
      }
    }
    CreateDnsRecord.new(@domain, record, @user).process
    dns = LoadDnsZoneRecords.new(@domain, @domain.user).process
    record = dns['records']['A'].first['dns_record']
    expect(record['ip']).to eq '1.2.3.4'
    expect(record['name']).to eq 'rspec'
  end
end
