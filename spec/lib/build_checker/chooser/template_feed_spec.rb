require 'rails_helper'

describe BuildChecker::Chooser::TemplateFeed do
  include_context :chooser_data
  let(:tf) { BuildChecker::Chooser::TemplateFeed.new(@started.first.location_id, 24.hours)}

  context 'with not tested templates scheduled' do
    before :each do
      @not_scheduled_templates = FactoryGirl.create_list(:template, 2, build_checker: true, location_id: @started.first.location_id)
    end

    it 'detects templates verified in the past and for schedule' do
      recent_template_ids = [@recent_check.template_id, @recent_same_loc.template_id]
      expect(tf.recent_template_tests.map(&:template_id).sort).to eq recent_template_ids.sort
    end

    it 'detects most recent tests for templates verified in the past and for schedule' do
      expect(tf.recent_template_tests.to_a.count).to eq 2
      expect(tf.recent_template_tests.map(&:start_after)).to include @recent_check_time
    end

    it 'detects ids of not tested, but choosen for tests templates' do
      expect(tf.not_tested_yet_template_ids.sort).to eq @not_scheduled_templates.map(&:id).sort
    end

    it 'returns build_checker test for farthest recent tested template' do
      expect(tf.farthest_recent_template_test).to eq @recent_same_loc
    end

    it 'returns template id for farthest recent tested template' do
      tf.instance_variable_set(:@time_gap_for_same_template, 1.hour)
      expect(tf.farthest_tested_template_id).to eq @recent_same_loc.template_id
      expect(tf.wait_time). to be_nil
    end

    it 'returns nil if time not passed for test of farthest recent tested template' do
      expect(tf.farthest_tested_template_id).to be_nil
      expect(tf.wait_time > 79100).to be_truthy
    end

    it 'returns not tested template id' do
      expect(@not_scheduled_templates.map(&:id)).to include tf.template_id_for_test
    end
  end

  context 'without not tested templates scheduled' do
    it 'returns farthest, from recent tests, template_id checked for tests' do
      tf.instance_variable_set(:@time_gap_for_same_template, 1.hour)
      expect(tf.farthest_tested_template_id).to eq @recent_same_loc.template_id
    end

    it 'returns nil if time not passed for test of farthest recent tested template' do
      expect(tf.farthest_tested_template_id).to be_nil
      expect(tf.wait_time > 71900).to be_truthy
    end

    it 'returns farthest, from recent tests, template_id checked for tests' do
      tf.instance_variable_set(:@time_gap_for_same_template, 1.hour)
      expect(tf.template_id_for_test).to eq @recent_same_loc.template_id
    end
  end


end
