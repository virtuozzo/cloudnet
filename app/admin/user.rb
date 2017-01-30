ActiveAdmin.register User do
  actions :all, except: [:destroy]
  menu priority: 6

  permit_params :email, :full_name, :admin, :onapp_user, :onapp_email, :vm_max, :cpu_max,
                :storage_max, :bandwidth_max, :memory_max, :password, :password_confirmation, :suspended,
                :notif_before_shutdown, :notif_before_destroy, :otp_mandatory, tag_ids: []

  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end

  filter :id
  filter :email
  filter :full_name
  filter :onapp_user
  filter :account_whitelisted_eq, as: :select, label: 'Whitelisted'
  filter :tags, as: :check_boxes, collection: proc { Tag.for(User) }

  filter :notif_delivered
  filter :last_notif_email_sent

  filter :admin
  filter :suspended
  filter :failed_attempts
  filter :otp_enabled
  filter :otp_mandatory
  filter :status
  filter :unconfirmed_email
  filter :servers_name, as: :string, label: 'Server Name'
  filter :keys

  filter :current_sign_in_ip
  filter :last_sign_in_ip
  filter :notif_before_shutdown
  filter :notif_before_destroy

  filter :created_at
  filter :updated_at
  filter :locked_at
  filter :reset_password_sent_at
  filter :confirmation_sent_at
  filter :confirmed_at
  filter :current_sign_in_at
  filter :last_sign_in_at
  
  remove_filter :keys

  index do
    column :id
    column :email
    column :current_sign_in_ip
    column :sign_in_count
    column :full_name
    column :minfraud_score do |user|
      user.account.billing_cards.map{|card| card.fraud_score.round(2).to_f}.max rescue nil
    end
    column :risky_cards do |user|
      user.account.risky_card_attempts rescue nil
    end
    column :admin
    column :suspended
    column :whitelisted do |user|
      status_tag(user.whitelisted?, label: boolean_to_words(user.whitelisted?)) rescue nil
    end
    column "Servers #" do |user|
      user.servers.count
    end
    column "Balance Notifications", :notif_delivered
    column :tags do |user|
      user.tag_labels.join(', ')
    end

    actions
  end

  show do

    default_main_content

    panel "Tags for a user" do
      attributes_table_for user do
        row :tags do |user|
          user.tag_labels.join(', ')
        end
      end
    end

    panel "Fraud Details" do
      fraud_body = JSON.parse user.account.primary_billing_card.fraud_body rescue nil
      attributes_table_for user do
        row :whitelisted do |user|
          status_tag(user.whitelisted?, label: boolean_to_words(user.whitelisted?)) unless user.account.nil?
        end
        row :minfraud_score do |user|
          user.account.max_minfraud_score unless user.account.nil?
        end
        row :sift_score do |user|
          if params[:show_sift]
            link_to user.sift_score, "https://siftscience.com/console/users/#{user.id.to_s}", target: '_blank' unless user.sift_user.nil?
          else
            link_to "Show", admin_user_path(user.id, show_sift: true)
          end
        end
        row :risky_cards do |user|
          user.account.risky_card_attempts unless user.account.nil?
        end
        row :stripe_account do |user|
          if !user.account.nil? && !user.account.gateway_id.nil?
            test_env = Rails.env.production? ? "" : "test/"
            link_to user.account.gateway_id, "https://dashboard.stripe.com/#{test_env}customers/#{user.account.gateway_id}", target: '_blank'
          end
        end
        row :primary_card_country_match do |user|
          boolean_to_words fraud_body['country_match'] unless fraud_body.nil?
        end
        row :primary_card_proxy_score do |user|
          fraud_body['proxy_score'] unless fraud_body.nil?
        end
        row :primary_card_anon_proxy do |user|
          boolean_to_words fraud_body['anonymous_proxy'] unless fraud_body.nil?
        end

        row :possible_duplicate_accounts do
          begin
            unless user.account.nil?
              duplicate_users = []
              matching_cards = []
              associated_ips = user.account.billing_cards.map {|card| card.ip_address}
              user.account.billing_cards.each do |card|
                BillingCard.with_deleted.where('account_id != ? AND (bin = ? AND last4 = ?)', user.account.id, card.bin, card.last4).map {|c| matching_cards.push c}
              end
              associated_ips.push [user.current_sign_in_ip, user.last_sign_in_ip]
              duplicate_users = User.with_deleted.where('id != ? AND (current_sign_in_ip IN (?) OR last_sign_in_ip IN (?))', user.id, associated_ips.flatten.uniq, associated_ips.flatten.uniq)
              billing_cards = BillingCard.with_deleted.where('account_id != ? AND ip_address IN (?)', user.account.id, associated_ips.flatten.uniq)
              billing_cards.map {|card| duplicate_users.push card.account.user unless card.account.blank?}
              matching_cards.map {|card| duplicate_users.push card.account.user unless card.account.blank?}
              raw duplicate_users.flatten.uniq.map {|user| link_to user.full_name, admin_user_path(user), target: '_blank' }.join(', ')
            end
          rescue StandardError => e
            ErrorLogging.new.track_exception(e, extra: { user: user, source: 'User#possible_duplicate_accounts' })
          end
        end

        # fraud validator methods
        row :minfraud_safe do |user|
          status_tag(user.account.minfraud_safe?, class: 'important', label: boolean_to_results(user.account.minfraud_safe?)) unless user.account.nil?
        end
        row :ip_history do |user|
          status_tag(user.account.safe_ip?, class: 'important', label: boolean_to_results(user.account.safe_ip?)) unless user.account.nil?
        end
        row :permissible_card_attempts do |user|
          status_tag(user.account.permissible_card_attempts?, class: 'important', label: boolean_to_results(user.account.permissible_card_attempts?)) unless user.account.nil?
        end
        row :card_history do |user|
          status_tag(user.account.safe_card?, class: 'important', label: boolean_to_results(user.account.safe_card?)) unless user.account.nil?
        end
        row :sift_actions_safe do |user|
          if params[:show_sift]
            status_tag(user.sift_valid?, class: 'important', label: boolean_to_results(user.sift_valid?)) unless user.sift_user.nil?
          else
            link_to "Show", admin_user_path(user.id, show_sift: true)
          end
        end
        row :sift_device_safe do |user|
          unless user.account.nil?
            if params[:show_sift]
              device_safe = !user.account.has_bad_device?
              status_tag(device_safe, class: 'important', label: boolean_to_results(device_safe))
            else
              link_to "Show", admin_user_path(user.id, show_sift: true)
            end
          end
        end
      end
    end
  end

  sidebar "Legend", only: :show do
    attributes_table_for user do
      row :minfraud_score do
        text_node "Minfraud score of customer's credit card. Higher the score, higher the possibility of fraud. If multiple cards in account, highest score is shown.".html_safe
      end
      row :risky_cards do
        text_node "Number of bad card attempts (rejected because of wrong info or high Minfraud scores)".html_safe
      end
      row :stripe_account do
        text_node "Quick link to account at Stripe".html_safe
      end
      row :primary_card_country_match do
        text_node "It indicates whether the country of user's IP address matched the billing address country of the primary credit card. A mismatch indicates a higher risk of fraud.".html_safe
      end
      row :primary_card_proxy_score do
        text_node "A score from 0.00-4.00 indicating the likelihood that the user’s IP address is high risk. Higher the score, higher the possibility of fraud. 0.5: 15%, 1.0: 30%, 2.0: 60%, 3.0+ 90% possible fraud.".html_safe
      end
      row :primary_card_anon_proxy do
        text_node "It indicates whether an anonymous proxy was used while adding a credit card. An anonymous proxy indicates a high risk of fraud.".html_safe
      end
      row :possible_duplicate_accounts do
        text_node "List of possible duplicate accounts inferred from IPs used to access the dashboard.".html_safe
      end
      row :minfraud_safe do
        text_node "Fail indicates that at least one credit card added to account has a risk score greater than 40.".html_safe
      end
      row :ip_history do
        text_node "Fail indicates an IP associated with this account was used for fraudulent activity in the past.".html_safe
      end
      row :permissible_card_attempts do
        text_node "Fail indicates number of attempts to add credit cards is above permissible limits (currently 3). ".html_safe
      end
      row :card_history do
        text_node "Fail indicates credit cards in account has been used for fraudulent activity in the past.".html_safe
      end
      row :sift_actions_safe do
        text_node "Fail indicates that account fails to pass formulas created at Sift Science console.".html_safe
      end
      row :sift_device_safe do
        text_node "Fail indicates that one of the devices associated with the account has been labelled bad.".html_safe
      end
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys

    f.inputs 'User Details' do
      f.input :full_name
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :admin
    end

    f.inputs 'VM Limits' do
      f.input :vm_max
      f.input :memory_max
      f.input :cpu_max
      f.input :storage_max
      f.input :bandwidth_max
    end

    f.inputs 'Tags' do
      f.input :tags, :multiple => true, as: :check_boxes
    end

    f.inputs 'Notification Limits - Before Action on Servers' do
      f.input :notif_before_shutdown
      f.input :notif_before_destroy
    end

    f.actions
  end

  controller do
    def scoped_collection
      result = super.includes({account: :billing_cards}, :tags)
      result.uniq! if params["commit"] == "Filter"
      result
    end

    def update
      user = params['user']
      if user && (user['password'].nil? || user['password'].empty?)
        user.delete('password')
        user.delete('password_confirmation')
      end
      user['otp_mandatory'] = user['admin']
      shutdown_destroy_notifications_activity(user)
      update!
      User.find(params[:id]).update_sift_account
    end

    def shutdown_destroy_notifications_activity(user)
      create_activity(user, :notif_before_shutdown_changed) if shutdown_changed?(user)
      create_activity(user, :notif_before_destroy_changed) if destroy_changed?(user)
    end

    def create_activity(user, activity)
      param = activity.to_s
      param.slice! '_changed'
      resource.create_activity(
        activity,
        owner: resource,
        params: {
          admin: current_user.id,
          from: resource.send(param),
          to: user[param].to_i
        }
      )
    end

    def shutdown_changed?(user)
      resource.notif_before_shutdown != user['notif_before_shutdown'].to_i
    end

    def destroy_changed?(user)
      resource.notif_before_destroy != user['notif_before_destroy'].to_i
    end

    def log_risky_entities(user)
      account = user.account
      unless account.nil?
        account.log_risky_ip_addresses
        account.log_risky_cards
      end
      create_sift_label(user)
      label_devices(user, "bad")
    end

    def create_sift_label(user)
      label_properties = SiftProperties.sift_label_properties true, nil, "Manually suspended", "manual_review", current_user.email
      SiftLabel.perform_async(:create, user.id.to_s, label_properties)
    end

    # Label all devices associated with user as 'bad' or 'not_bad'
    def label_devices(user, label)
      LabelDevices.perform_async(user.id, label)
    end

    def remove_sift_label(user)
      SiftLabel.perform_async(:remove, user.id.to_s)
    end
  end

  collection_action :notify_users, method: :get do
    @page_title = 'Notify Users'
  end

  collection_action :send_users_notification, method: :post do
    users = User.all

    subject = params['notify_users']['subject']
    email_body = AppHelper.new.markdown(params['notify_users']['message'], false)

    users.find_each do |user|
      user_info = { email: user.email, full_name: user.full_name }
      NotifyUsersMailer.delay.notify_email(user_info, subject, email_body)
    end

    flash[:notice] = 'Notification has been emailed to all users'
    redirect_to admin_users_path
  end

  member_action :confirm_user, method: :post do
    user = User.find(params[:id])
    user.confirm! unless user.confirmed?

    flash[:notice] = 'User has been confirmed successfully'
    redirect_to admin_user_path(id: user.id), notice: 'User suspended'
  end

  member_action :activity, method: :get do
    @activities = PublicActivity::Activity.where(owner_id: params[:id], owner_type: 'User').order('created_at DESC').page(params[:page]).per(50)
  end

  # Display form to manually add credit note
  member_action :issue_credit_note, method: :get do
    user = User.find(params[:id])
    @page_title = "Issue Credit Note for #{user.full_name}"
  end

  # Receive post data from :issue_credit_note form. Not displayed.
  member_action :submit_credit_note, method: :post do
    user = User.find(params[:id])
    amount = params[:issue_credit_note][:amount]
    reason = params[:issue_credit_note][:reason]
    CreditNote.manually_issue user.account, amount, reason, current_user
    flash[:notice] = "Credit Note successfully issued for $#{amount}"
    redirect_to issue_credit_note_admin_user_path(user)
  end

  member_action :suspend, method: :post do
    user = User.find(params[:id])
    log_risky_entities(user)
    user.update_attribute(:suspended, true)
    ShutdownAllUserServers.perform_async(user.id)
    user.create_activity(:suspend, owner: user, params: { admin: current_user.id })

    flash[:notice] = 'User has been suspended'
    redirect_to admin_user_path(id: user.id)
  end

  member_action :unsuspend, method: :post do
    user = User.find(params[:id])
    user.update_attribute(:suspended, false)

    remove_sift_label(user)
    label_devices(user, "not_bad")

    flash[:notice] = 'User has been unsuspended'
    redirect_to admin_user_path(id: user.id)
  end
  
  member_action :disable_api, method: :post do
    user = User.find(params[:id])
    user.update_attribute(:api_enabled, false)
    user.create_activity(:disable_api, owner: user, params: { admin: current_user.id })

    flash[:notice] = 'API has been disabled'
    redirect_to admin_user_path(id: user.id)
  end
  
  member_action :enable_api, method: :post do
    user = User.find(params[:id])
    user.update_attribute(:api_enabled, true)
    user.create_activity(:enable_api, owner: user, params: { admin: current_user.id })

    flash[:notice] = 'API has been enabled'
    redirect_to admin_user_path(id: user.id)
  end
  
  member_action :add_whitelist, method: :post do
    user = User.find(params[:id])
    user.account.update_attribute(:whitelisted, true)
    user.create_activity(:add_whitelist, owner: user, params: { admin: current_user.id })

    flash[:notice] = 'User has been whitelisted'
    redirect_to admin_user_path(id: user.id)
  end
  
  member_action :remove_whitelist, method: :post do
    user = User.find(params[:id])
    user.account.update_attribute(:whitelisted, false)
    user.create_activity(:remove_whitelist, owner: user, params: { admin: current_user.id })

    flash[:notice] = 'User has been removed from whitelist'
    redirect_to admin_user_path(id: user.id)
  end

  member_action :disable_two_factor, method: :post do
    user = User.find(params[:id])
    user.disable_otp! if user.otp_enabled?

    flash[:notice] = 'Two factor auth has been disabled for this user'
    redirect_to admin_user_path(id: user.id)
  end

  action_item :edit, only: :show do
    link_to 'Confirm User', confirm_user_admin_user_path(user), method: :post unless user.confirmed?
  end

  action_item :edit, only: :show do
    link_to('Suspend User', suspend_admin_user_path(user), method: :post) unless user.suspended?
  end

  action_item :edit, only: :show do
    link_to 'Unsuspend User', unsuspend_admin_user_path(user), method: :post if user.suspended?
  end

  action_item :edit, only: :show do
    link_to 'User Activity', activity_admin_user_path(user)
  end

  action_item :edit, only: :show do
    link_to 'Login As User', login_as_path(user_id: user.id), method: :post unless user.suspended?
  end

  action_item :edit, only: :show do
    link_to 'Issue Credit Note', issue_credit_note_admin_user_path(user)
  end

  action_item :edit, only: :show do
    link_to 'Disable Two Factor Auth', disable_two_factor_admin_user_path(user), method: :post if user.otp_enabled?
  end
  
  action_item :edit, only: :show do
    link_to('Disable API', disable_api_admin_user_path(user), method: :post) if user.api_enabled?
  end

  action_item :edit, only: :show do
    link_to('Enable API', enable_api_admin_user_path(user), method: :post) unless user.api_enabled?
  end
  
  action_item :edit, only: :show do
    link_to('Whitelist User', add_whitelist_admin_user_path(user), method: :post) if !user.suspended? && !user.whitelisted?
  end

  action_item :edit, only: :show do
    link_to('Remove from Whitelist', remove_whitelist_admin_user_path(user), method: :post) if !user.suspended? && user.whitelisted?
  end

  action_item :edit, only: :index do
    link_to 'Notify All Users', notify_users_admin_users_path
  end

end
