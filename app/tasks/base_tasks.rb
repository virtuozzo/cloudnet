class BaseTasks
  def allowable_methods
    [:hello]
  end

  def run_task(action, *args)
    if allowable_methods.include?(action)
      send(action, *args)
    else
      fail NoMethodError, "Not allowed to access method #{action}"
    end
  end

  private

  def hello
    'Hello!'
  end
end
