require 'rails_helper'

describe ServerUsage do
  let(:server_usage) { FactoryGirl.create(:server_usage) }

  it 'should be a valid server usage record' do
    expect(server_usage).to be_valid
  end

  it 'should allow CPU usage and Network usage records' do
    server_usage.usage_type = :network
    expect(server_usage).to be_valid

    server_usage.usage_type = :cpu
    expect(server_usage).to be_valid
  end

  it 'should not allow other types of records' do
    server_usage.usage_type = :test
    expect(server_usage).not_to be_valid
  end

  it 'is invalid without a collection of usages' do
    server_usage.usages = ''
    expect(server_usage).not_to be_valid
  end

  it 'should pluck the CPU usages for a server if they exist' do
    server = server_usage.server
    usages = ServerUsage.cpu_usages(server)
    expect(usages).not_to be_empty
  end

  it "should return an empty array if usages don't exist for a server" do
    server = FactoryGirl.create(:server)
    usages = ServerUsage.cpu_usages(server)
    expect(usages).to eq([])
  end
end
