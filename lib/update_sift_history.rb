## Send existing users and their past acivities to Sift Science 
## as per https://siftscience.com/resources/tutorials/sending-historical-data
## Meant to be run once Sift science is deployed on production

class UpdateSiftHistory
  def self.run
    new.run
  end
  
  def run
    User.find_each do |user|
      begin
        puts "User: #{user.email}"
        puts "Suspended: #{user.suspended}"
        # Temporarily un-suspend user
        suspended = user.suspended
        user.update_attribute(:suspended, false) if suspended
        
        UpdateSiftHistoryTask.new(user, suspended).process
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'UpdateSiftHistory' })
      ensure
        if suspended
          user.update_attribute(:suspended, true)
          user.update_sift_account
        end
      puts "==============================================================="
      end
    end
  end
end
