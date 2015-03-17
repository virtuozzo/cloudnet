if Rails.env.production?
  Pry.config.prompt_name = "\e[4m\e[31mpry-production\e[0m"
end
