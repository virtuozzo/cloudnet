require 'rails_helper'

describe ApplicationController do
  it 'should not be in development mode' do
    expect(controller.development?).to be false
  end
end
