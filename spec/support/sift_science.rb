RSpec.configure do |config|
  config.before(:each) do
    @sift_client_double = double('SiftClientTasks', perform: nil)
    allow(SiftClientTasks).to receive(:new).and_return(@sift_client_double)
    
    @sift_device_double = double('SiftDeviceTasks', perform: nil)
    allow(SiftDeviceTasks).to receive(:new).and_return(@sift_device_double)
  end
end
