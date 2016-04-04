web:      bundle exec puma -e ${RACK_ENV:-production}
sidekiq:  bundle exec sidekiq -C config/sidekiq.yml
cron:     sh start-cron.sh
