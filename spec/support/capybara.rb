require 'capybara/rspec'
require 'capybara/rails'

Capybara.configure do |config|
  config.ignore_hidden_elements = false
  config.visible_text_only = false
end
