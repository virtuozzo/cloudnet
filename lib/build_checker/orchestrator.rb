module BuildChecker
  # start and stop all build checker services
  class Orchestrator
    include BuildChecker::Logger
    @@threads = []

    Signal.trap("HUP") { exit }
    at_exit do
      BuildChecker.clear_pid!
      ActiveRecord::Base.clear_active_connections!
      exit! if @@threads.blank?
      @@threads.each {|thr| thr.exit }
      @@threads.each {|thr| thr.join }
      logger.info "Build Checker stopped"
    end

    def self.run
      Process.setproctitle('build checker 1.0.0')
      new.run
    end

    def initialize
      ActiveRecord::Base.clear_active_connections! and exit! if running?
      return if build_checker_user_exists?
      logger.error "You must create build_checker user before. Use: rake create_build_checker_user"
      exit
    end

    def run
      running!
      logger.info "Build Checker started"
      prepare_threads
    end

    def prepare_threads
      @@threads << queue_builder_start
      @@threads << build_processor_start
      @@threads << vm_monitor_start
      @@threads << cleaner_start
      sleep
    end

    def queue_builder_start
      Thread.new { Builder::QueueBuilder.run }
    end

    def build_processor_start
      Thread.new { Builder::BuildProcessor.run }
    end

    def vm_monitor_start
      Thread.new { BuildChecker::Monitor::BuildMonitor.run }
    end

    def cleaner_start
      Thread.new { Cleaner::CleanProcessor.run }
    end

    def running!
      BuildChecker.running!
    end

    def running?
      BuildChecker.running?
    end


    def quick_exit!
      ActiveRecord::Base.clear_active_connections!
      exit!
    end

    def build_checker_user_exists?
      return false unless user = User.find_by(email: 'build_checker_fake_email')
      return false unless user.onapp_id # taken from OnApp create_user call
      true
    end
  end
end