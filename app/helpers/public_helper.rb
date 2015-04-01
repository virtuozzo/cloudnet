module PublicHelper
  def initial_parameters_form
    content_tag(:div)
  end
  
  def region_select
    label_tag(:region, "Region") +
    select_tag(:region, options_for_select(region_options), class: "pure-input-1")
  end
  
  def cpu_select
    label_tag(:cpu, "CPU") +
    select_tag(:cpu, options_for_select(cpu_options), class: "pure-input-1")
  end
  
  def mem_select
    label_tag(:mem, "Memory") +
    select_tag(:mem, options_for_select(mem_options), class: "pure-input-1")
  end
  
  def disc_select
    label_tag(:disc, "Disc") +
    select_tag(:disc, options_for_select(disc_options), class: "pure-input-1")
  end
  
  def region_options
    [['Global', 'global']]
  end
  
  def cpu_options
    [['1 core', 1],  ['2 cores', 2], ['3 cores', 3], ['4 cores', 4]]
  end
  
  def mem_options
    [['512 MB', 512], ['1024 MB', 1024], ['2560 MB', 2560], ['5120 MB', 5120]]
  end
  
  def disc_options
    [['10 GB', 10], ['20 GB', 20], ['40 GB', 40], ['60 GB', 60]]
  end
  
  def summary_param(label, abbr, value)
    content_tag :p do
      abbr = ("&nbsp;" + abbr).html_safe
      classes = ["pull-right", "value"]
      label.html_safe +
      content_tag(:span, abbr, class: classes) +
      content_tag(:span, value, class: classes)
    end
  end
end
