require 'rails_helper'

describe VCD do
  before do
    @wizard = ServerWizard.new
    @wizard.user = FactoryGirl.build(
      :user,
      onapp_user: 'cloudnetvcd',
      onapp_password: ENV['VCDEMO_PASS']
    )
    @wizard.name = 'rspectest'
    @wizard.location = FactoryGirl.create :location
    @wizard.template = Template.create!(
      location: @wizard.location,
      identifier: 254,
      vmid: 'vm-c9fc20b5-14ce-40c8-a4ed-e9c23e734bf7',
      name: 'CentOS',
      os_type: 'vCD',
      onapp_os_distro: 'vCD',
      os_distro: 'vCD'
    )
  end

  it 'should create a vapp', :vcr do
    VCD.create_vapp @wizard
  end
end
