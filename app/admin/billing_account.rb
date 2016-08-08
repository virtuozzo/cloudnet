ActiveAdmin.register_page 'Billing Accounts' do
  content do
    render 'index'
  end

  page_action :account_report, method: :post do
    if params['account_report'].present?
      start_date = Date.strptime params['account_report']['start'], '%Y-%m-%d'
      end_date   = Date.strptime params['account_report']['end'], '%Y-%m-%d'

      SendAdminFinancials.perform_async(:periodic_csv, start_date, end_date, :account_report, current_user.id)
      flash[:notice] = "Report will be emailed to you once generated"
      redirect_to admin_billing_accounts_path
    end
  end

  page_action :transaction_report, method: :post do
    if params['transaction_report'].present?
      start_date = Date.strptime params['transaction_report']['start'], '%Y-%m-%d'
      end_date   = Date.strptime params['transaction_report']['end'], '%Y-%m-%d'
      
      SendAdminFinancials.perform_async(:periodic_csv, start_date, end_date, :transaction_report, current_user.id)
      flash[:notice] = "Report will be emailed to you once generated"
      redirect_to admin_billing_accounts_path
    end
  end

  page_action :charge_report, method: :post do
    if params['charge_report'].present?
      start_date = Date.strptime params['charge_report']['start'], '%Y-%m-%d'
      end_date   = Date.strptime params['charge_report']['end'], '%Y-%m-%d'

      SendAdminFinancials.perform_async(:periodic_csv, start_date, end_date, :charge_report, current_user.id)
      flash[:notice] = "Report will be emailed to you once generated"
      redirect_to admin_billing_accounts_path
    end
  end
end
