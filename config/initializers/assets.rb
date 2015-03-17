# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0.2'
Rails.application.assets.register_engine('.haml', Tilt::HamlTemplate)

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

# Adds additional error checking when serving assets at runtime.
# Checks for improperly declared sprockets dependencies.
# Raises helpful error messages.
Rails.application.config.assets.raise_runtime_errors = true

Rails.application.config.assets.precompile += %w( server_search.js )

Rails.application.assets.context_class.class_eval do
  include ApplicationHelper
  include ActionView::Helpers
  include Rails.application.routes.url_helpers
end