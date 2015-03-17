namespace :deploy do
  task remove_cached_js: :environment do
    Rails.cache.delete_matched('js_minified_')
  end
end
