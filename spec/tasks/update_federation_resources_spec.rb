require 'rails_helper'

describe UpdateFederationResources, :vcr do
  it 'should update resources from the federation' do
    UpdateFederationResources.run
    expect(Location.count).to eq 1
    expect(Template.count).to eq 38
  end
end
