class UpdateIndices
  include Sidekiq::Worker
  sidekiq_options unique: true
  
  def perform
    IndicesTasks.new.perform(:update_all_locations)
  end
end
