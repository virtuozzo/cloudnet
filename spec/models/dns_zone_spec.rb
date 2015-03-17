require 'rails_helper'

describe DnsZone do
  let (:dns) { FactoryGirl.create(:dns_zone) }

  it 'should be valid' do
    expect(dns).to be_valid
  end

  it 'should not be valid without a domain name' do
    dns.domain = nil
    expect(dns).not_to be_valid
  end

  it 'should not be valid without a user' do
    dns.user = nil
    expect(dns).not_to be_valid
  end

  it 'should change any http(s) values and remove them from the hostname' do
    %w(joel.com http://joel.com https://joel.com).each do |domain|
      dns.domain = domain
      expect(dns.domain).to eq('joel.com')
    end

    dns.domain = 'http:/joel.com'
    expect(dns.domain).to eq('http:/joel.com')
  end

  it 'should convert the autopopulate value to a boolean' do
    dns.autopopulate = 1
    expect(dns.autopopulate).to be true

    dns.autopopulate = '1'
    expect(dns.autopopulate).to be true

    dns.autopopulate = 'true'
    expect(dns.autopopulate).to be true

    dns.autopopulate = 0
    expect(dns.autopopulate).to be false

    dns.autopopulate = '0'
    expect(dns.autopopulate).to be false

    dns.autopopulate = 'false'
    expect(dns.autopopulate).to be false
  end

  it 'should process records coming in from OnApp DNS' do
    test_data = '{"created_at":"2014-05-07T16:02:48+01:00","id":3,"name":"tester.com","updated_at":"2014-05-07T16:02:48+01:00","user_id":3,"records":{"SOA":[{"dns_record":{"expire":2419200,"hostmaster":"suhail@onapp.com","id":428388,"minimum":10800,"name":"@","primaryNs":"ns1.onapp-support.com","refresh":7200,"retry":900,"serial":1312014050,"ttl":300,"type":"SOA"}}],"NS":[{"dns_record":{"hostname":"ns1.onapp-support.com","id":428384,"name":"@","ttl":86400,"type":"NS"}},{"dns_record":{"hostname":"ns2.onapp-support.com","id":428385,"name":"@","ttl":86400,"type":"NS"}},{"dns_record":{"hostname":"ns3.onapp-support.com","id":428386,"name":"@","ttl":86400,"type":"NS"}},{"dns_record":{"hostname":"ns4.onapp-support.com","id":428387,"name":"@","ttl":86400,"type":"NS"}}],"A":[{"dns_record":{"id":428390,"ip":"216.40.47.17","name":"@","ttl":300,"type":"A"}},{"dns_record":{"id":428391,"ip":"64.99.80.30","name":"blog","ttl":300,"type":"A"}},{"dns_record":{"id":428392,"ip":"64.99.80.30","name":"cdn","ttl":300,"type":"A"}},{"dns_record":{"id":428393,"ip":"64.99.80.30","name":"chat","ttl":300,"type":"A"}},{"dns_record":{"id":428394,"ip":"64.99.80.30","name":"community","ttl":300,"type":"A"}},{"dns_record":{"id":428395,"ip":"64.99.80.30","name":"forum","ttl":300,"type":"A"}},{"dns_record":{"id":428396,"ip":"64.99.80.30","name":"ftp","ttl":300,"type":"A"}},{"dns_record":{"id":428397,"ip":"64.99.80.30","name":"imap","ttl":300,"type":"A"}},{"dns_record":{"id":428399,"ip":"64.99.80.30","name":"pop","ttl":300,"type":"A"}},{"dns_record":{"id":428400,"ip":"64.99.80.30","name":"secure","ttl":300,"type":"A"}},{"dns_record":{"id":428401,"ip":"64.99.80.30","name":"shop","ttl":300,"type":"A"}},{"dns_record":{"id":428402,"ip":"64.99.80.30","name":"smtp","ttl":300,"type":"A"}},{"dns_record":{"id":428403,"ip":"64.99.80.30","name":"ssl","ttl":300,"type":"A"}},{"dns_record":{"id":428404,"ip":"64.99.80.30","name":"store","ttl":300,"type":"A"}},{"dns_record":{"id":428407,"ip":"64.99.80.30","name":"www2","ttl":300,"type":"A"}},{"dns_record":{"id":428408,"ip":"64.99.80.30","name":"mx","ttl":300,"type":"A"}},{"dns_record":{"id":428409,"ip":"64.99.80.30","name":"autodiscover","ttl":300,"type":"A"}}],"CNAME":[{"dns_record":{"hostname":"mail.netidentity.com.cust.hostedemail.com","id":428398,"name":"mail","ttl":300,"type":"CNAME"}},{"dns_record":{"hostname":"mail.netidentity.com.cust.hostedemail.com","id":428405,"name":"webmail","ttl":300,"type":"CNAME"}},{"dns_record":{"hostname":"c.internettraffic.com","id":428406,"name":"www","ttl":300,"type":"CNAME"}}],"MX":[{"dns_record":{"hostname":"mx.netidentity.com.cust.hostedemail.com","id":428389,"name":"@","priority":10,"ttl":300,"type":"MX"}}]},"cdn_reference":34337363}'
    records = DnsZone.process_records(JSON.parse(test_data))

    # Should include fields of all types of records
    DnsZone::RECORD_TYPES.each do |type|
      expect(records.keys.include?(type.to_sym)).to be true
    end

    # Expect 1 SOA record, 4 NS records, 17 A Records, 3 CNAME records, 0 AAAA records
    expect(records[:soa].size).to eq(1)
    expect(records[:ns].size).to eq(4)
    expect(records[:a].size).to eq(17)
    expect(records[:aaaa].size).to eq(0)
    expect(records[:cname].size).to eq(3)
  end
end
