require 'rails_helper'

describe DashboardStats do
  let (:user) { FactoryGirl.create(:user) }
  let (:servers) { user.servers }

  it 'should have the basic elemental structure' do
    stats = DashboardStats.gather_stats(user, servers)

    expect(stats.key?(:memory)).to be true
    expect(stats.key?(:cpus)).to be true
    expect(stats.key?(:disk_size)).to be true
    expect(stats.key?(:bandwidth)).to be true
    expect(stats.key?(:tickets)).to be true
  end

  it 'should have zero totals and elements initially' do
    stats = DashboardStats.gather_stats(user, servers)

    %w(memory cpus disk_size bandwidth).each do |e|
      expect(stats[e.to_sym][:usage]).to eq(0)
      expect(stats[e.to_sym][:split].size).to eq(0)
    end

    expect(stats[:tickets].size).to eq(0)
  end

  it 'should respond to a single element added in servers' do
    server = FactoryGirl.create(:server, user: user, memory: 256, cpus: 8, disk_size: 20, bandwidth: 1000)
    stats = DashboardStats.gather_stats(user, servers)

    expect(stats[:memory][:usage]).to     eq(256)
    expect(stats[:cpus][:usage]).to       eq(8)
    expect(stats[:disk_size][:usage]).to  eq(20)
    expect(stats[:bandwidth][:usage]).to  eq(1000)

    %w(memory cpus disk_size bandwidth).each do |e|
      expect(stats[e.to_sym][:split].size).to eq(1)
      expect(stats[e.to_sym][:split].first[:id]).to eq(server.id)
    end
  end

  it 'should total multiple elements in servers' do
    server1 = FactoryGirl.create(:server, user: user, memory: 1024, cpus: 8, disk_size: 10, bandwidth: 1000)
    server2 = FactoryGirl.create(:server, user: user, memory: 2048, cpus: 1, disk_size: 20, bandwidth: 3000)
    server3 = FactoryGirl.create(:server, user: user, memory: 2048, cpus: 5, disk_size: 25, bandwidth: 5000)
    server4 = FactoryGirl.create(:server, memory: 2048, cpus: 5, disk_size: 25, bandwidth: 5000) # This one shouldn't be included because it's a different user
    stats = DashboardStats.gather_stats(user, servers)

    expect(stats[:memory][:usage]).to     eq(5120)
    expect(stats[:cpus][:usage]).to       eq(14)
    expect(stats[:disk_size][:usage]).to  eq(55)
    expect(stats[:bandwidth][:usage]).to  eq(9000)

    %w(memory cpus disk_size bandwidth).each do |e|
      expect(stats[e.to_sym][:split].size).to eq(3)
    end

    [server1, server2, server3].each do |s|
      %w(memory cpus disk_size bandwidth).each do |e|
        expect(stats[e.to_sym][:split].select { |se| se[:id] == s.id }.size).to eq(1)
        expect(stats[e.to_sym][:split].select { |se| se[:id] == server4.id }.size).to eq(0)
      end
    end
  end

  it "should have a total of zero monthly costs if user doesn't have any" do
    expect(user.servers.count).to eq(0)
    stats = DashboardStats.gather_costs(user, servers)

    expect(stats[:memory][:monthly]).to eq(0)
    expect(stats[:cpus][:monthly]).to eq(0)
    expect(stats[:disk_size][:monthly]).to eq(0)
    expect(stats[:bandwidth][:monthly]).to eq(0)
  end

  it 'should total monthly costs of all servers' do
    s1 = FactoryGirl.create(:server, user: user, memory: 1024, cpus: 8, disk_size: 10, bandwidth: 1000)
    s2 = FactoryGirl.create(:server, user: user, memory: 2048, cpus: 1, disk_size: 20, bandwidth: 3000)
    s3 = FactoryGirl.create(:server, user: user, memory: 2048, cpus: 5, disk_size: 25, bandwidth: 5000)
    stats = DashboardStats.gather_costs(user, servers)

    hours = Account::HOURS_MAX
    expect(stats[:memory][:monthly]).to eq([s1, s2, s3].sum { |s| s.ram_invoice_item(hours)[:net_cost] })
    expect(stats[:cpus][:monthly]).to eq([s1, s2, s3].sum { |s| s.cpu_invoice_item(hours)[:net_cost] })
    expect(stats[:disk_size][:monthly]).to eq([s1, s2, s3].sum { |s| s.disk_invoice_item(hours)[:net_cost] })
    expect(stats[:bandwidth][:monthly]).to eq([s1, s2, s3].sum { |s| s.bandwidth_free_invoice_item(hours)[:net_cost] })
  end
end
