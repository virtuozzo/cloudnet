class SiftTasks < BaseTasks

  def perform(action, event, properties, *args)
    sift_science = SiftScience.new
    run_task(action, sift_science, event, properties, *args)
  end

  private

  def create_event(sift_science, event, properties)
    sift_science.create_event(event, properties)
  end

  def allowable_methods
    super + [:create_event]
  end
end
