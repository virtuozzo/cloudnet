require 'rails_helper'

describe BuildChecker::Chooser::LocationFeed do
  include_context :chooser_data
  let(:lf) { BuildChecker::Chooser::LocationFeed.new(30.seconds)}

  context 'with not tested locations scheduled' do
    before :each do
      @not_scheduled_templates = FactoryGirl.create_list(:template, 2, build_checker: true)
    end

    it 'finds location ids for which templates are to be scheduled' do
      location_ids_for_schedule = template_ids_for_schedule.map { |id| Template.find(id).location_id }.uniq
      expect(lf.to_be_scheduled_location_ids.sort).to eq (location_ids_for_schedule).sort
    end

    it 'detects locations verified in the past and for schedule' do
      expect(lf.recent_locations_tests.map(&:location_id).sort).to eq @started.map(&:location_id).sort
    end

    it 'detects most recent tests for location verified in the past and for schedule' do
      expect(lf.recent_locations_tests.to_a.count).to eq 2
      expect(lf.recent_locations_tests.map(&:start_after)).to include @recent_check_time
    end

    it 'detects ids of not tested, but choosen for tests locations' do
      expect(lf.not_tested_yet_location_ids.sort).to eq @not_scheduled_templates.map { |t| t.location_id }.sort
    end

    it 'returns build_checker tests only for locations ready for next build' do
      lf.instance_variable_set(:@time_gap_for_same_location, 1.hours + 10.minutes)
      expect(lf.sorted_tests).to eq [@started.second]
    end

    it 'returns build_checker tests sorted from farthest in time first' do
      expect(lf.sorted_tests.size).to eq 2
      expect(lf.sorted_tests.first).to eq @started.second
      expect(lf.wait_time).to be_nil
    end

    it 'returns empty table if no location ready for new test' do
      lf.instance_variable_set(:@time_gap_for_same_location, 4.hours + 10.minutes)
      expect(lf.sorted_tests).to be_empty
      expect(lf.wait_time > 500).to be_truthy
    end

    it 'returns not tested location ids checked for tests' do
      expect(lf.sorted_locations_ids_for_test.sort).to eq @not_scheduled_templates.map { |t| t.location_id }.sort
    end
  end

  context 'without not tested locations scheduled' do
    it 'returns sorted, from farthest, tested location ids checked for tests' do
      expect(lf.sorted_locations_ids_for_test).to eq [@started.second.location_id, @started.first.location_id]
    end

    it 'returns empty table if no location ready for new test' do
      lf.instance_variable_set(:@time_gap_for_same_location, 4.hours + 10.minutes)
      expect(lf.sorted_locations_ids_for_test).to be_empty
      expect(lf.wait_time > 500).to be_truthy
    end
  end
end
