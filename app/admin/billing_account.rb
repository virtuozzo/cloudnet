ActiveAdmin.register_page 'Billing Accounts' do
  content do
    render 'index'
  end

  page_action :account_report, method: :post do
    if params['account_report'].present?
      start_date = Date.strptime params['account_report']['start'], '%Y-%m-%d'
      end_date   = Date.strptime params['account_report']['end'], '%Y-%m-%d'

      filename = "cloudnet_account_report_#{start_date}_#{end_date}.csv"
      send_data GenerateFinanceReport.new(start_date, end_date).account_report, filename: filename
    end
  end

  page_action :transaction_report, method: :post do
    if params['transaction_report'].present?
      start_date = Date.strptime params['transaction_report']['start'], '%Y-%m-%d'
      end_date   = Date.strptime params['transaction_report']['end'], '%Y-%m-%d'

      filename = "cloudnet_transaction_report_#{start_date}_#{end_date}.csv"
      send_data GenerateFinanceReport.new(start_date, end_date).transaction_report, filename: filename
    end
  end

  page_action :charge_report, method: :post do
    if params['charge_report'].present?
      start_date = Date.strptime params['charge_report']['start'], '%Y-%m-%d'
      end_date   = Date.strptime params['charge_report']['end'], '%Y-%m-%d'

      filename = "cloudnet_charge_report_#{start_date}_#{end_date}.csv"
      send_data GenerateFinanceReport.new(start_date, end_date).charge_report, filename: filename
    end
  end
end
