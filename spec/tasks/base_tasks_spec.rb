require 'rails_helper'

describe BaseTasks do
  let (:base) { BaseTasks.new }

  it 'should call the relevant action for valid calls' do
    expect(base.run_task(:hello)).to eq('Hello!')
  end

  it 'should raise errors for invalid calls or calls not allowed to access' do
    expect { base.run_task(:invalid) }.to raise_error(NoMethodError)
  end
end
