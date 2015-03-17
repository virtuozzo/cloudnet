require 'simplecov'

# SimpleCov Code Coverage setup
SimpleCov.start 'rails' do
  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Services', 'app/services'
  add_group 'Tasks', 'app/tasks'
  add_group 'Workers', 'app/workers'
end
