# Builds test VMs using all accessible templates
module BuildChecker
  PID_KEY = 'build_checker_pid'
  STATUS_KEY = 'build_checker_status' # running, stopped, stopping

  def self.running?
    (status.empty? || status == "stopped") && pid == 0 ? false : true
  end

  def self.stopped?
    status == "stopped"
  end

  def self.stopping?
    status == "stopping"
  end

  def self.running!
    System.set(PID_KEY, Process.pid)
    System.set(STATUS_KEY, :running)
  end

  def self.pid
    System.get(PID_KEY).to_i
  end

  def self.clear_pid!
    System.clear(PID_KEY)
  end

  def self.status=(status)
    System.set(STATUS_KEY, status)
  end

  def self.status
    System.get(STATUS_KEY)
  end
end