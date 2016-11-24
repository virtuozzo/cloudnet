# Builds test VMs using all accessible templates
module BuildChecker
  PID_KEY = 'build_checker_pid'

  def self.running?
    System.get(PID_KEY).present?
  end

  def self.running!
    System.set(PID_KEY, Process.pid)
  end

  def self.pid
    System.get(PID_KEY).to_i
  end

  def self.clear_pid!
    System.clear(PID_KEY)
  end
end