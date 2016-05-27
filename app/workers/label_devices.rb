class LabelDevices
  include Sidekiq::Worker

  def perform(user_id, label)
    return nil if KEYS[:sift_science][:api_key].blank?
    begin
      devices = SiftDeviceTasks.new.perform(:get_devices, user_id)
      if !devices.nil? && !devices["data"].nil?
        devices["data"].each do |device|
          device_id = device["id"]
          SiftDeviceTasks.new.perform(:label_device, device_id, label)
          # users = SiftDeviceTasks.new.perform(:get_device, device_id)
          # users["users"]["data"].each do |user|
          #   # TODO: Mark user as bad ? or maybe mark devices of user as bad ?
          # end
        end
      end
    rescue StandardError => e
      ErrorLogging.new.track_exception(e,
        extra: {
          source: 'LabelDevices',
          user_id: user_id,
          label: label
        }
      )
    end
  end
end
