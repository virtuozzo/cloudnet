require 'rails_helper'

describe BuildChecker::Chooser::TemplateChooser do
  include_context :chooser_data
  let(:chooser) { BuildChecker::Chooser::TemplateChooser.new }

  it 'sets variables' do
    tc = BuildChecker::Chooser::TemplateChooser.config do |tc|
      tc.time_gap_for_same_template = 1.hour
      tc.time_gap_for_same_location = 1.second
    end

    expect(tc.time_gap_for_same_template).to eq 1.hour
    expect(tc.time_gap_for_same_location).to eq 1.second
  end

  context 'with not tested locations and templates scheduled' do
    before :each do
      @not_scheduled_templates1 = FactoryGirl.create_list(:template, 2, build_checker: true)
      @not_scheduled_templates2 = FactoryGirl.create_list(:template, 2, build_checker: true, location_id: @started.first.location_id)
    end

    it 'returns location ids' do
      expect(chooser.location_ids.sort).to eq @not_scheduled_templates1.map { |t| t.location_id }.sort
    end

    it 'returns template id' do
      expect(@not_scheduled_templates2.map(&:id)).to include chooser.template_id(@started.first.location_id)
    end

    it 'returns next template for test' do
      expect(@not_scheduled_templates1.map(&:id)).to include chooser.next_template_id
    end
  end

  context 'without not tested locations scheduled' do
    it 'returns location ids' do
      expect(chooser.location_ids).to eq [@started.second.location_id, @started.first.location_id]
    end

    it 'returns template id' do
      chooser.time_gap_for_same_template = 1.hour
      expect(chooser.template_id(@started.first.location_id)).to eq @recent_same_loc.template_id
    end

    it 'returns next template for test from first sorted location' do
      chooser.time_gap_for_same_template = 1.hour
      expect(chooser.next_template_id).to eq @started.second.template_id
    end

    it 'returns next template for test from second sorted location' do
      template = FactoryGirl.create(:template, location_id: @started.first.location_id, build_checker: true)
      result = FactoryGirl.create(:build_checker_datum, template_id: template.id, start_after: Time.now - 6.hours)

      chooser.time_gap_for_same_template = 5.hours
      expect(chooser.next_template_id).to eq template.id
    end

    it 'returns nil if no template is ready for test' do
      expect(chooser.next_template_id).to be_nil
    end
  end

end