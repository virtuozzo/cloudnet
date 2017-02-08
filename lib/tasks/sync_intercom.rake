# Syncs existing users to Intercom

task sync_intercom: :environment do  
  intercom = Intercom::Client.new(token: ENV['INTERCOM_ACCESS_TOKEN'])
  
  User.find_in_batches(batch_size: 100).with_index do |users, batch|
    begin
      puts "Processing batch #{batch}"
      items = []
      users.each do |user|
        items << {  name: user.full_name, 
                    email: user.email, 
                    user_id: user.id, 
                    phone: user.phone_number, 
                    last_seen_ip: user.last_sign_in_ip, 
                    signed_up_at: user.created_at.to_i, 
                    last_request_at: user.last_sign_in_at.to_i, 
                    custom_attributes: { location_hash: user.intercom_location_hash } 
                }
      end
      # p items
      job = intercom.users.submit_bulk_job(create_items: items)
      puts "Job ID #{job.id} has state #{job.state}"
      job_status = intercom.jobs.find(id: job.id)
      puts "Job has task status #{job_status.tasks.first['state']}"
      job_errors = intercom.jobs.errors(id: job.id)
      errors = job_errors.items.map {|e| e["data"]["user_id"].to_s + " - " + e["error"]["status"] + " - " + e["error"]["message"]}
      puts "Job errors: #{errors}"
      puts "\n"
    rescue => e
      puts e
    end
  end
end
