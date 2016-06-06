class SiftClientTasks < BaseTasks

  def perform(action, *args)
    return nil if KEYS[:sift_science][:api_key].blank?
    sift_client = SiftScience::Client.new
    run_task(action, sift_client, *args)
  end

  private

  def create_event(sift_client, event, properties, return_action = false)
    sift_client.create_event(event, properties, return_action)
  end
  
  def create_label(sift_client, user_id, properties)
    sift_client.create_label(user_id, properties)
  end
  
  def remove_label(sift_client, user_id)
    sift_client.remove_label(user_id)
  end
  
  def get_score(sift_client, user_id)
    sift_client.score(user_id)
  end

  def allowable_methods
    super + [:create_event, :create_label, :remove_label, :get_score]
  end
end
