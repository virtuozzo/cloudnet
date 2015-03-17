ActionView::Base.class_eval do
  class_variable_set(:@@field_error_proc, proc { |html_tag, _instance| "<div class=\"field_with_errors\">#{html_tag}</div>".html_safe })
end
