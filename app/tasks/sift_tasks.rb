class SiftTasks < BaseTasks

  def perform(action, *args)
    return nil if KEYS[:sift_science][:api_key].blank?
    sift_science = SiftScience.new
    run_task(action, sift_science, *args)
  end

  private

  def create_event(sift_science, event, properties)
    sift_science.create_event(event, properties)
  end
  
  def create_label(sift_science, user_id, properties)
    sift_science.create_label(user_id, properties)
  end
  
  def remove_label(sift_science, user_id)
    sift_science.remove_label(user_id)
  end
  
  def get_score(sift_science, user_id)
    sift_science.score(user_id)
  end

  def allowable_methods
    super + [:create_event, :create_label, :remove_label, :get_score]
  end
end
