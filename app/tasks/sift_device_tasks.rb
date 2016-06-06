class SiftDeviceTasks < BaseTasks

  def perform(action, *args)
    return nil if KEYS[:sift_science][:api_key].blank?
    sift_device = SiftScience::Device.new
    run_task(action, sift_device, *args)
  end

  private

  def get_session(sift_device, session_id)
    device = sift_device.session(session_id)
    device.body["device"]
  end
  
  def get_device(sift_device, device_id)
    device = sift_device.device(device_id)
    device.body
  end
  
  def label_device(sift_device, device_id, label)
    label = sift_device.label(device_id, label)
    label.body
  end
  
  def get_devices(sift_device, user_id)
    devices = sift_device.devices(user_id.to_s)
    devices.body
  end

  def allowable_methods
    super + [:get_session, :get_device, :label_device, :get_devices]
  end
end
