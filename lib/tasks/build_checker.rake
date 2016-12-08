namespace :build_checker do
  desc 'start build checker'
  task start: :environment do
    logger = Logger.new('log/build_checker.log')
    logger.level = Logger::DEBUG
    Rails.logger = ActiveSupport::TaggedLogging.new(logger)
    Process.daemon
    BuildChecker::Orchestrator.run
  end

  desc 'stop build checker'
  task stop: :environment do
    begin
      pid = BuildChecker.pid
      Process.kill('INT', BuildChecker.pid) if pid > 0
    rescue Exception
      nil
    end
  end

  desc 'creates build checker user'
  task create_user: :environment do
    worker_size = Sidekiq::ProcessSet.new.size rescue 0
    fail 'Sidekiq not active.' if worker_size == 0

    user = User.new(full_name: 'build_checker', email: 'build_checker_fake_email')
    begin
      user.save(validate: false)
      puts "User 'build_checker' created. Wait a moment for OnApp update."

    rescue ActiveRecord::RecordNotUnique
      puts "User already exists in local DB"
    end
  end
end
