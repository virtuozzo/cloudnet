class BandwidthChecker
  # do not send notifications before time pass since invoice
  NOTIFICATION_MIN_HOURS_SINCE_DUE_DATE = 48

  # user notifications
  MAX_USER_NOTIFICATIONS_IN_BILLING_PERIOD = 4
  GAP_BETWEEN_USER_NOTIFICATIONS_HOURS = 48
  NOTIFICATION_USER_AFTER_EXCEEDED_GB = 20

  # admin notifications (verify potential fraud)
  MAX_ADMIN_NOTIFICATIONS_IN_BILLING_PERIOD = 4
  NOTIFICATION_ADMIN_AFTER_EXCEEDED_GB = 50

  attr_reader :server

  def initialize(server)
    @server = server
  end

  def check_bandwidth
    inform_user if user_conditions_met?
    inform_admin if admin_conditions_met?
  end

  def user_conditions_met?
    minimum_time_since_due_date? &&
    user_notifications_gap_met? &&
    user_notifications_under_limit? &&
    bandwidth_threshold_exceeded?(user_notification_threshold)
  end

  def minimum_time_since_due_date?
    billing_bandwidth.hours_since_last_due_date > NOTIFICATION_MIN_HOURS_SINCE_DUE_DATE
  end

  def user_notifications_gap_met?
    return true if server.exceed_bw_user_last_sent.nil?
    (Time.now - server.exceed_bw_user_last_sent) / 1.hour > GAP_BETWEEN_USER_NOTIFICATIONS_HOURS
  end

  def user_notifications_under_limit?
    server.exceed_bw_user_notif < MAX_USER_NOTIFICATIONS_IN_BILLING_PERIOD
  end

  # 0 20 40 60
  def user_notification_threshold
    NOTIFICATION_USER_AFTER_EXCEEDED_GB * 1024 * server.exceed_bw_user_notif
  end

  def admin_conditions_met?
    minimum_time_since_due_date? &&
    admin_notifications_under_limit? &&
    bandwidth_threshold_exceeded?(admin_notification_threshold)
  end

  def admin_notifications_under_limit?
    server.exceed_bw_admin_notif < MAX_ADMIN_NOTIFICATIONS_IN_BILLING_PERIOD
  end

  # 50 100
  def admin_notification_threshold
    NOTIFICATION_ADMIN_AFTER_EXCEEDED_GB * 1024 * (server.exceed_bw_admin_notif + 1)
  end

  def inform_user
    NotifyUsersMailer.delay.notify_bandwidth_exceeded(server, paid_bandwidth)
    server.update_attribute(:exceed_bw_value, paid_bandwidth)
    server.update_attribute(:exceed_bw_user_last_sent, Time.now)
    server.increment!(:exceed_bw_user_notif)
  end

  def inform_admin
    AdminMailer.delay.notify_bandwidth_exceeded(server, paid_bandwidth)
    server.increment!(:exceed_bw_admin_notif)
  end

  # calculation in MB
  def bandwidth_threshold_exceeded?(threshold)
    paid_bandwidth > (reported_bandwidth + threshold)
  end

  def paid_bandwidth
    @paid_bandwidth ||= billing_bandwidth.bandwidth_usage[:billable]
  end

  def billing_bandwidth
    @billing_bandwidth ||= Billing::BillingBandwidth.new(server)
  end

  def reported_bandwidth
    @reported_bandwidth ||= server.exceed_bw_value
  end
end