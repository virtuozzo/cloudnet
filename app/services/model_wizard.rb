class ModelWizard
  attr_reader :object

  def initialize(object_or_class, session, params = nil, param_key = nil)
    @object_or_class = object_or_class
    @session = session
    @params = params
    @param_key = param_key
    @session_params = "#{@param_key}_params".to_sym
  end

  def reset_session
    @session[@session_params] = {}
    self
  end

  def start
    reset_session
    process
    @object.current_step = 1
    self
  end

  def process
    @session[@session_params].deep_merge!(@params[@param_key].symbolize_keys) if @params and @params[@param_key]
    set_object
    @object.assign_attributes(@session[@session_params]) unless class?
    self
  end

  def save
    case
      when back_button_pressed? then step_back and unsaved
      when current_step_is_not_valid? then unsaved
      when not_last_step? then step_forward and unsaved
      when all_steps_valid? then try_save
      else unsaved
    end
  end

  private

  def back_button_pressed?
    @params[:back_button]
  end

  def step_back
    @object.step_back
  end

  def step_forward
    @object.step_forward
  end

  def unsaved
    false
  end

  def all_steps_valid?
    @object.all_steps_valid?
  end

  def try_save
    @session[@session_param] = nil
    @object.save
  end

  def current_step_is_not_valid?
    !@object.current_step_valid?
  end

  def not_last_step?
    !@object.last_step?
  end

  def set_object
    @object = class? ? @object_or_class.new(@session[@session_params]) : @object_or_class
  end

  def class?
    @object_or_class.is_a?(Class)
  end
end
