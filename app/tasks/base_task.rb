class BaseTask
  def initialize(*_args)
  end

  def success?
    errors.empty?
  end

  def errors?
    errors.present?
  end

  def errors
    @build_errors ||= []
  end
end
