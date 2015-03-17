namespace :billing do
  desc 'List the users that are going to get charged each billing date'
  task billing_days: :environment do
    (1..31).each do |num|
      date = Date.today.change(day: num, month: 1)
      puts "Day: #{date.day}"

      Account.invoice_day(date).find_each do |account|
        user    = account.user
        servers = user.servers.where(in_beta: false).where('created_at < ?', account.past_invoice_due)
        next if servers.empty?

        puts ">> #{user} (#{user.email}) - Servers: #{servers.count}"
      end
    end
  end
end
