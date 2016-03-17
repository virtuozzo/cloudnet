#!/bin/sh

printenv | sed 's/^\(.*\)$/export \1/g' > /root/.profile
bundle exec whenever -w
cron -f
