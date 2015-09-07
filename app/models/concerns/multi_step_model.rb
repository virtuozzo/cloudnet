# based on https://github.com/nerdcave/rails-multistep-form/blob/master/app/models/concerns/multi_step_model.rb
module MultiStepModel
  attr_accessor :current_step

  def current_step
    @current_step.to_i
  end

  def current_step_valid?
    valid?
  end

  def all_steps_valid?
    (1..self.total_steps).all? do |step|
      @current_step = step
      current_step_valid?
    end
  end

  def step_forward
    @current_step = current_step + 1
  end

  def step_back
    @current_step = current_step - 1
  end

  def step?(step)
    @current_step.nil? || current_step == step
  end

  def last_step?
    step?(self.total_steps)
  end

  def first_step?
    step?(1)
  end

  def method_missing(method_name, *args, &block)
    if /^step(\d+)\?$/ =~ method_name
      step?(Regexp.last_match[1].to_i)
    else
      super
    end
  end
end
