source 'https://rubygems.org'

gem 'dotenv-rails'
gem 'foreman', require: false

gem 'rails', '4.2'
gem 'activerecord-session_store'

gem 'haml-rails', '~> 0.5.3'
gem 'sass-rails'
gem 'uglifier', '~> 2.5.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'jquery-rails'
gem 'compass-rails'

gem 'paranoia', '~> 2.0.2'
gem 'kaminari', '~> 0.15.1'
gem 'gretel', '~> 3.0.6'
gem 'redcarpet', '~> 3.1.1'
gem 'public_activity', '~> 1.4.1'

gem 'turbolinks'
gem 'jbuilder', '~> 1.2'

gem 'devise', git: 'https://github.com/plataformatec/devise.git'
gem 'devise-otp'

gem 'angularjs-rails', '~> 1.3.15'
gem 'underscore-rails', '~> 1.8.2'

gem 'sidekiq', '~> 3.2'
gem 'sinatra', '>= 1.4.5', require: false
gem 'sidekiq-unique-jobs'

gem 'faraday', '~> 0.9.0'
gem 'faraday-http-cache', '~> 0.4.0'
gem 'squall', git: 'https://github.com/suhailpatel/squall.git', ref: '49d5db8'
gem 'symmetric-encryption', '~> 3.4.0'
gem 'iso_country_codes', '~> 0.4.4'
gem 'country_select', github: 'stefanpenner/country_select'
gem 'carmen-rails', '~> 1.0.1'

# Billing Integration Dependencies
gem 'stripe', git: 'https://github.com/stripe/stripe-ruby', ref: '9cf5089d'
gem 'maxmind', '~> 0.4.5'
gem 'prawn', '~> 1.3.0'
gem 'prawn-table'
gem 'sequenced', '~> 1.6.0'
gem 'paypal-express', '~> 0.6.0'

# Zendesk Integration Dependencies
gem 'zendesk_api', '~> 1.5.0'

gem 'whenever', require: false
gem 'turnout'
gem 'figaro'

# Admin functions
gem 'responders', '~> 2.0'
gem 'activeadmin', github: 'activeadmin'
gem 'inherited_resources', github: 'josevalim/inherited_resources', branch: 'rails-4-2'
gem 'pghero'

# Sentry Exception Logging
gem 'sentry-raven', git: 'https://github.com/getsentry/raven-ruby.git'

# Segment.io Analytics Tracking
gem 'analytics-ruby', '~> 2.0.0', require: 'segment/analytics'

gem 'pry-rails', '0.3.2'

gem 'capistrano', '~> 3.2.1'
gem 'capistrano-rails', '~> 1.1.1'
gem 'capistrano3-puma', '~> 1.0.0'
gem 'capistrano-sidekiq', '~> 0.5.2'
gem 'capistrano-upload-config'

# Fixtures
gem 'yaml_db'

group :development, :test do
  gem 'guard'
  gem 'guard-rails'
  gem 'guard-livereload', require: false
  gem 'guard-sidekiq'
  gem 'guard-rspec', require: false
  gem 'rb-readline'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'quiet_assets'
  gem 'jasmine-rails'
  gem 'jasmine-jquery-rails'
end

group :test do
  gem 'minitest' # Apparently AR *has* to have this, see: https://github.com/rspec/rspec-rails/issues/758
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'selenium-webdriver'
  gem 'capybara'
  gem 'faker'
  gem 'database_cleaner'
  gem 'webmock'
  gem 'vcr'
  gem 'launchy'
  gem 'simplecov'
  gem 'timecop'
  gem 'fuubar'
  gem 'brakeman'
  gem 'rails_best_practices'
  gem 'mock_redis'
end

gem 'puma', '~> 2.9.0'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

gem 'pg'

group :production do
  gem 'dalli'
  gem 'kgio'
  gem 'newrelic_rpm'
end

group :staging do
  gem 'rails_12factor'
end
