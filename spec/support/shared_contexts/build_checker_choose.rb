shared_context :chooser_data do

  let(:template_ids_for_schedule) { @not_scheduled_templates.map(&:id) + @started.map(&:template_id) + [@same_loc_template.id] }

  before :all do
    @not_choosen_templates = FactoryGirl.create_list(:template, 2)
    @not_choosen_templates.map(&:id).each do |id|
      time =  Time.now - rand(1..10).hour
      FactoryGirl.create(:build_checker_datum, template_id: id, start_after: time )
    end

    @scheduled = FactoryGirl.create_list(:build_checker_datum, 2, scheduled: true)
    @scheduled.each { |bcd| bcd.template.update_attribute(:build_checker, true) }

    @started = FactoryGirl.create_list(:build_checker_datum, 2, start_after: Time.now - 4.hours)
    @started.each { |bcd| bcd.template.update_attribute(:build_checker, true) }

    @recent_check = FactoryGirl.create(:build_checker_datum, template_id: @started.first.template_id, start_after: Time.now - 1.hour)
    @recent_check_time = @recent_check.reload.start_after

    @same_loc_template = FactoryGirl.create(:template, location_id: @started.first.location_id, build_checker: true)
    FactoryGirl.create(:build_checker_datum, template_id: @same_loc_template.id, start_after: Time.now - 6.hours)
    @recent_same_loc = FactoryGirl.create(:build_checker_datum, template_id: @same_loc_template.id, start_after: Time.now - 2.hours)

    @same_loc_not_scheduled_template = FactoryGirl.create(:template, location_id: @started.first.location_id)
    FactoryGirl.create(:build_checker_datum, template_id: @same_loc_not_scheduled_template.id, start_after: Time.now - 3.hour)
  end

  after :all do
    BuildChecker::Data::BuildCheckerDatum.delete_all
    Template.delete_all
    Location.delete_all
    Region.delete_all
    Package.delete_all
  end
end