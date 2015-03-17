require 'rails_helper'

describe Template do
  let (:template) { FactoryGirl.create(:template) }

  it 'should be a valid template' do
    expect(template).to be_valid
  end

  it 'is invalid without a name' do
    template.name = ''
    expect(template).not_to be_valid
  end

  it 'is invalid without an identifier' do
    template.identifier = nil
    expect(template).not_to be_valid
  end

  it 'is invalid without an os type' do
    template.os_type = ''
    expect(template).not_to be_valid
  end

  it 'is invalid without an os distro' do
    template.os_distro = ''
    expect(template).not_to be_valid
  end

  it 'is invalid without a location' do
    template.location = nil
    expect(template).not_to be_valid
  end
end
