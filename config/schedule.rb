# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

env :PATH, ENV['PATH']
set :output, 'log/cron.log'

every 2.minutes, roles: [:app] do
  runner 'RefreshAllServers.perform_in(2.minutes)'
end

every 20.minutes, roles: [:app] do
  runner 'RefreshServerUsages.perform_in(2.minutes)'
end

every 1.hour, at: '12:30 am' do
  runner 'RemoveCouponCodes.perform_in(2.minutes)'
end

every '0 * * * *', roles: [:app] do
  runner 'ServerUsageHourly.perform_in(1.minute)'
end

# Create invoices (does not create charges)
every 1.day, at: '1:00 am' do
  runner 'AutoBilling.perform_in(2.minutes)'
end

# Create charges for outstanding balances, uses Credit Notes, Payment Receipts and CCs
every 1.day, at: '1:30 am' do
  runner 'ChargeUnpaidInvoices.perform_in(2.minutes)'
end

# Email daily financial reports
every 1.day, at: '2:00 am' do
  runner 'SendAdminFinancials.perform_in(2.minutes, :daily)'
end

# Sending warning emails to users with negative balance
every 1.day, at: '2:30 am' do
  runner 'NegativeBalanceCheckerTask.perform_in(4.minutes)'
end

# Update uptime for servers
every 1.day, at: '3:00am' do
  runner 'UptimeAllUpdate.perform_in(5.minutes)'
end


# Email monthly financial reports
every '0 1 1 * *' do
  runner 'SendAdminFinancials.perform_in(2.minutes, :monthly_csv)'
end
