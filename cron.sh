touch /var/log/cron.log
touch /app/log/cron.log
whenever --write-crontab --set environment=$RAILS_ENV
cron
tail -f /var/log/cron.log
