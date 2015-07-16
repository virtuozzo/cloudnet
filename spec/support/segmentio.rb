RSpec.configure do |config|
  config.before(:each) do
    analytics_double = double('Segment::Analytics', identify: true, track: true, alias: true, flush: true)
    allow(Segment::Analytics).to receive(:new).and_return(analytics_double)
  end

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!
end
