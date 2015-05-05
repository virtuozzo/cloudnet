task find_duplicate_server_transactions: :environment do
  count = 0
  Server.payg.each do |server|
    puts server.id
    previous = false
    server.server_hourly_transactions.each do |transaction|
      if previous
        diff = transaction.created_at - previous.created_at
        if diff > 0 && diff < 120
          puts "#{diff}s : #{previous.created_at}, #{transaction.created_at}"
          count += 1
        end
      end
      previous = transaction
    end
  end
  puts "Transactions within 2 minutes of each other: #{count}"
end
