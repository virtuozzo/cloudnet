touch /var/log/cron.log
touch /app/log/cron.log
whenever --set environment=$RAILS_ENV --set job_template="env \$(cat /app/env/.env | xargs) bash -l -c ':job'" -w
cron
tail -f /var/log/cron.log
