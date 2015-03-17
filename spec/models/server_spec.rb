require 'rails_helper'

describe Server do
  let(:server) { FactoryGirl.create(:server) }

  it 'has a valid server' do
    expect(server).to be_valid
  end

  it 'is invalid without an identifier' do
    server.identifier = ''
    expect(server).not_to be_valid
  end

  it 'is invalid without a name' do
    server.name = ''
    expect(server).not_to be_valid
  end

  it 'should be in the off state by default' do
    expect(server.state_building?).to be true
  end

  it 'is invalid without a valid user' do
    server.user = nil
    expect(server).not_to be_valid
  end

  it 'is invalid without a location' do
    server.location = nil
    expect(server).not_to be_valid
  end

  it 'is invalid without a template' do
    server.template = nil
    expect(server).not_to be_valid
  end
end
