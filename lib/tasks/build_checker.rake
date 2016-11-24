task run_build_checker: :environment do
  BuildChecker::Orchestrator.run
end

task stop_build_checker: :environment do
  Process.kill('HUP', BuildChecker.pid) rescue nil
end

task create_build_checker_user: :environment do
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
