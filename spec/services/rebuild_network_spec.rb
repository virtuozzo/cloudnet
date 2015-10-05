require 'rails_helper'

describe RebuildNetwork do
  it 'should rebuild network of server' do
    network = double('Squall::Network', rebuild: true)
    allow(Squall::Network).to receive(:new).and_return(network)
    
    user = FactoryGirl.create(:user)
    server = FactoryGirl.create(:server, user: user)
    RebuildNetwork.new(server, server.user).process
    expect(network).to have_received(:rebuild)
  end
end