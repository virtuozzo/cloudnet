require 'rails_helper'

describe ServerEvent do
  let(:event) { FactoryGirl.create(:server_event) }

  it 'should be a valid event' do
    expect(event).to be_valid
  end

  it "should be invalid if it doesn't have a server" do
    event.server = nil
    expect(event).not_to be_valid
  end

  it "should be invalid if it doesn't have an action" do
    event.action = ''
    expect(event).not_to be_valid
  end

  it "should be invalid if it doesn't have a status" do
    event.status = ''
    expect(event).not_to be_valid
  end

  describe 'event status' do
    it 'should be complete if status is complete' do
      event.status = 'complete'
      expect(event.complete?).to be true
    end

    it 'should be incomplete if status is not complete' do
      event.status = 'pending'
      expect(event.incomplete?).to be true
    end

    it 'should be failed if status is failed' do
      event.status = 'failed'
      expect(event.failed?).to be true
    end

    it 'should be running if status is running' do
      event.status = 'running'
      expect(event.running?).to be true
    end

    it 'should be cancelled if status is cancelled' do
      event.status = 'cancelled'
      expect(event.cancelled?).to be true
    end

    it 'should be pending if status is pending' do
      event.status = 'pending'
      expect(event.pending?).to be true
    end

    it 'should be finished if status is complete, failed or cancelled' do
      event.status = 'pending'
      expect(event.finished?).not_to be true

      event.status = 'failed'
      expect(event.finished?).to be true
    end
  end
end
