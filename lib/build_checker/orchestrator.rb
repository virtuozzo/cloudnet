module BuildChecker
  # start and stop all build checker services
  class Orchestrator
    include BuildChecker::Logger
    include BuildChecker::Data
    @@threads = {}

    Signal.trap("INT") { exit }
    at_exit do
      logger.info "Start exit procedure"
      exit!(true) unless ActiveRecord::Base.connected?
      clear_pid
      if @@threads.blank?
        set_status(:stopped)
        ActiveRecord::Base.clear_active_connections!
        exit!
      end
      finish_builds
      ActiveRecord::Base.clear_active_connections!
      logger.info "Build Checker stopped"
    end

    def self.run
      Process.setproctitle('build checker 1.0.0')
      new.run
    end

    def initialize
      quick_exit! if running?
      return if build_checker_user_exists?
      logger.error "You must create build_checker user before. Use: rake build_checker:create_user"
      exit
    end

    def run
      running!
      logger.info "Build Checker started"
      prepare_threads
    end

    def prepare_threads
      @@threads[:stucked] = stucked_tasks_monitor_start
      @@threads[:queue]   = queue_builder_start
      @@threads[:build]   = build_processor_start
      @@threads[:monitor] = vm_monitor_start
      @@threads[:cleaner] = cleaner_start
      sleep 10 until BuildChecker.stopping?
      exit
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

    def stucked_tasks_monitor_start
      Thread.new { BuildChecker::Monitor::StuckedTasksMonitor.run }
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

    def self.clear_pid
      BuildChecker.clear_pid! if BuildChecker.pid == Process.pid
    end

    def self.finish_builds
      set_status(:stopping) # in case of exit by signal trap
      @@threads[:queue].exit rescue nil
      @@threads[:build].exit rescue nil
      @@threads[:queue].join rescue nil
      @@threads[:build].join rescue nil
      sleep 10 while tasks_to_finish?
      @@threads.each {|_,thr| thr.exit rescue nil }
      @@threads.each {|_,thr| thr.join rescue nil }
      set_status(:stopped)
    end

    def self.tasks_to_finish?
      BuildCheckerDatum.where.not(state: [
        BuildCheckerDatum.states["scheduled"],
        BuildCheckerDatum.states["finished"]
        ]).count > 0
    end

    def self.set_status(status)
      BuildChecker.status = status
    end
  end
end
