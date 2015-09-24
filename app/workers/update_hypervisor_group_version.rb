class UpdateHypervisorGroupVersion
  include Sidekiq::Worker
  sidekiq_options unique: true
  
  def perform
    squall = Squall::HypervisorZone.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
    hv_zones = squall.list
    hv_zones.each do |hv_zone|
      location = Location.where(hv_group_id: hv_zone["id"]).first
      next if location.nil?
      location.update_attribute(:hv_group_version, hv_zone["supplier_version"])
    end
  end
end
