class AdminMailer < ActionMailer::Base
  ADMIN_RECIPIENTS = ENV['MAILER_ADMIN_RECIPIENTS'].split(',')
  FINANCE_RECIPIENTS = ENV['MAILER_FINANCE_RECIPIENTS'].split(',')
  SUPPORT_RECIPIENTS = ENV['MAILER_SUPPORT_RECIPIENTS'].split(',')

  default from: ENV['MAILER_ADMIN_DEFAULT_FROM']

  def financials(data, mailto = ADMIN_RECIPIENTS)
    @data = data
    @date = data[:date]
    mail(to: mailto, subject: "#{ENV['BRAND_NAME']} Admin Report - #{@date}")
  end

  def monthly_csv(start_date, end_date, mailto = FINANCE_RECIPIENTS)
    @date_name = start_date.strftime('%B %Y')
    reporter = GenerateFinanceReport.new(start_date, end_date)

    filename = "cloudnet_monthly_account_report_#{@date_name}.csv"
    attachments[filename] = reporter.account_report

    filename = "cloudnet_monthly_transaction_report_#{@date_name}.csv"
    attachments[filename] = reporter.transaction_report

    filename = "cloudnet_monthly_charge_report_#{@date_name}.csv"
    attachments[filename] = reporter.charge_report

    mail(to: mailto, subject: "#{ENV['BRAND_NAME']} Monthly CSV Reports - #{@date_name}")
  end

  def periodic_csv(start_date, end_date, report, admin_id)
    @start_date, @end_date, @report = start_date, end_date, report
    admin_user = User.where(admin: true, id: admin_id).first
    filename = "cloudnet_#{report.to_s}_#{@start_date}_#{@end_date}.csv"
    reporter = GenerateFinanceReport.new(@start_date, @end_date)
    attachments[filename] = reporter.send(@report)
    mail(to: admin_user.email, subject: "#{ENV['BRAND_NAME']} Billing Reports")
  end

  def cost_analysis(mailto = FINANCE_RECIPIENTS)
    time = Time.now
    @date_name = time.strftime("#{ActiveSupport::Inflector.ordinalize(time.day)} %B %Y")
    report = CostAnalysisReport.new

    filename = "cloudnet_cost_analysis_report_#{@date_name}.csv"
    attachments[filename] = report.generate

    mail(to: mailto, subject: "#{ENV['BRAND_NAME']} Cost Analysis Report - #{@date_name}")
  end

  def notify_stuck_server_state(server)
    @server = server
    @stuck_duration = "#{((Time.zone.now - @server.last_state_change) / 60).floor} minutes"
    @link_to_onapp_server = "#{ENV['ONAPP_CP']}/virtual_machines/#{@server.identifier}"
    mail(to: SUPPORT_RECIPIENTS, subject: "#{ENV['BRAND_NAME']} Server stuck in intermediate state")
  end

  def shutdown_action(user)
    @user = user
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: ADMIN_RECIPIENTS,
      subject: "#{ENV['BRAND_NAME']}: Automatic shutdown - #{user.full_name}"
    )
  end

  def destroy_warning(user)
    @user = user
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: ENV['MAILER_ADMIN_RECIPIENTS'],
      subject: "#{ENV['BRAND_NAME']}: DESTROY warning! - #{user.full_name}"
    )
  end

  def request_for_server_destroy(user)
    @user = user
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: ENV['MAILER_ADMIN_RECIPIENTS'],
      subject: "#{ENV['BRAND_NAME']}: DESTROY request! - #{user.full_name}"
    )
  end

  def destroy_action(user)
    @user = user
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: ADMIN_RECIPIENTS,
      subject: "#{ENV['BRAND_NAME']}: Automatic destroy - #{user.full_name}"
    )
  end

  def notify_bandwidth_exceeded(server, bandwidth_over)
    @server = server
    # changing MB to Bytes
    @bandwidth_over = bandwidth_over * 1024 * 1024
    @link_to_onapp_server = "#{ENV['ONAPP_CP']}/virtual_machines/#{@server.identifier}"
    mail(
      to: ADMIN_RECIPIENTS,
      subject: "#{ENV['BRAND_NAME']}: User #{server.user.full_name} is exceeding free bandwidth allocation"
    )
  end

  def notify_faulty_server(server, no_disk, no_ip)
    @server, @no_disk, @no_ip = server, no_disk, no_ip
    @link_to_onapp_server = "#{ENV['ONAPP_CP']}/virtual_machines/#{server.identifier}"
    mail(
      to: ADMIN_RECIPIENTS,
      subject: "#{ENV['BRAND_NAME']}: Faulty server for user #{server.user.full_name}"
    )
  end

  def notify_automatic_invoice(server, old_server_specs)
    @server, @old_server_specs = server, old_server_specs
    @link_to_onapp_server = "#{ENV['ONAPP_CP']}/virtual_machines/#{server.identifier}"
    mail(
      to: ADMIN_RECIPIENTS,
      subject: "#{ENV['BRAND_NAME']}: VM parameters discrepancy - automatic billing for user #{server.user.full_name}"
    )
  end
end
