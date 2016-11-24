require 'rails_helper'

describe BuildChecker::Chooser::BaseFeed do
  include_context :chooser_data
  let(:bf) { BuildChecker::Chooser::BaseFeed.new}

  it 'finds already scheduled template ids' do
    expect(bf.already_scheduled_template_ids.sort).to eq @scheduled.map(&:template_id).sort
  end

  it 'finds all choosen template ids' do
    ids = @scheduled.map(&:template_id) + @started.map(&:template_id) + [@same_loc_template.id]
    expect(bf.template_ids.sort).to eq ids.sort
  end

  it 'finds all choosen template ids for specific location' do
    bf.instance_variable_set(:@location_id, @started.first.location_id)
    ids = [@started.first.template.id, @same_loc_template.id].sort
    expect(bf.template_ids.sort).to eq ids.sort
  end

  it 'finds template ids for schedule' do
    ids = @started.map(&:template_id) + [@same_loc_template.id]
    expect(bf.to_be_scheduled_template_ids.sort).to eq ids.sort
  end

  it 'finds template ids for schedule for specific location' do
    bf.instance_variable_set(:@location_id, @started.first.location_id)
    ids = [@started.first.template.id, @same_loc_template.id].sort
    expect(bf.to_be_scheduled_template_ids.sort).to eq ids.sort
  end
end