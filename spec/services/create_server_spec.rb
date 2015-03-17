require 'rails_helper'

describe CreateServer do
  it 'should call the VM create instance' do
    vm = double('Squall::VirtualMachine', create: true)
    allow(Squall::VirtualMachine).to receive(:new).and_return(vm)

    server1 = FactoryGirl.create(:server, memory: 256, disk_size: 10, cpus: 4, bandwidth: 10)
    CreateServer.new(server1, server1.user).process
    expect(vm).to have_received(:create)
  end

  it 'should return a blank string if no IP from server' do
    result = CreateServer.extract_ip('ip_addresses' => [])
    expect(result).to eq('')
  end

  it 'should return the first IP from server' do
    result = CreateServer.extract_ip('ip_addresses' => [{ 'ip_address' => { 'address' => '192.168.1.1' } }])
    expect(result).to eq('192.168.1.1')
  end
end
