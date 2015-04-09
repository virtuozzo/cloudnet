namespace :deploy do
  task remove_cached_js: :environment do
    Rails.cache.delete_matched('js_minified_')
  end
  
  desc 'Clears the Rails cache'
  task cache_flush: :environment do
    Rails.cache.clear
  end
end
