require 'rails_helper'

describe BaseTask do
  let(:base) { BaseTask.new }

  it 'should have success if there are no errors' do
    expect(base.errors).to be_empty
    expect(base.success?).to be true
  end

  it 'should not have success if there are errors' do
    base.errors << 'This is an error'
    expect(base.success?).not_to be true
  end

  it 'should have errors as false if there are no errors' do
    expect(base.errors).to be_empty
    expect(base.errors?).to be false
  end

  it 'should have errors as true if there are errors' do
    base.errors << 'This is an error'
    expect(base.errors?).to be true
  end

  it 'should return the list of errors' do
    expect(base.errors).to eq([])
    base.errors << 'This is an error'
    expect(base.errors).to eq(['This is an error'])
  end
end
