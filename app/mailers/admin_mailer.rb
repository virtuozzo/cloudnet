class AdminMailer < ActionMailer::Base
  ADMIN_RECIPIENTS = ENV['MAILER_ADMIN_RECIPIENTS'].split(',')
  FINANCE_RECIPIENTS = ENV['MAILER_FINANCE_RECIPIENTS'].split(',')
  SUPPORT_RECIPIENTS = ENV['MAILER_SUPPORT_RECIPIENTS'].split(',')

  default from: ENV['MAILER_ADMIN_DEFAULT_FROM']

  def financials(data, mailto = ADMIN_RECIPIENTS)
    @data = data
    @date = data[:date]
    mail(to: mailto, subject: "Cloud.net Admin Report - #{@date}")
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

    mail(to: mailto, subject: "Cloud.net Monthly CSV Reports - #{@date_name}")
  end

  def notify_stuck_server_state(server)
    @server = server
    @stuck_duration = "#{((Time.zone.now - @server.last_state_change) / 60).floor} minutes"
    @link_to_onapp_server = "#{ENV['ONAPP_CP']}/virtual_machines/#{@server.identifier}"
    mail(to: SUPPORT_RECIPIENTS, subject: 'Cloud.net Server stuck in intermediate state')
  end
end
