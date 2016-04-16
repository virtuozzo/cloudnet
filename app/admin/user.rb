ActiveAdmin.register User do
  actions :all, except: [:destroy]
  menu priority: 6
  
  permit_params :email, :full_name, :admin, :onapp_user, :onapp_email, :vm_max, :cpu_max,
                :storage_max, :bandwidth_max, :memory_max, :password, :password_confirmation, :suspended,
                :notif_before_shutdown, :notif_before_destroy

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

  filter :notif_delivered
  filter :last_notif_email_sent

  filter :admin
  filter :suspended
  filter :failed_attempts
  filter :otp_enabled
  filter :otp_mandatory
  filter :status
  filter :unconfirmed_email
  filter :servers
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
    column "Balance Notifications", :notif_delivered

    actions
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

    f.inputs 'Notification Limits - Before Action on Servers' do
      f.input :notif_before_shutdown
      f.input :notif_before_destroy
    end
    
    f.actions
  end

  controller do
    def update
      user = params['user']
      if user && (user['password'].nil? || user['password'].empty?)
        user.delete('password')
        user.delete('password_confirmation')
      end
      shutdown_destroy_notifications_activity(user)
      update!
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
    @activities = PublicActivity::Activity.where(owner_id: params[:id], owner_type: 'User').order('created_at DESC')
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
    user.update!(suspended: true)

    flash[:notice] = 'User has been suspended'
    redirect_to admin_user_path(id: user.id)
  end

  member_action :unsuspend, method: :post do
    user = User.find(params[:id])
    user.update!(suspended: false)

    flash[:notice] = 'User has been unsuspended'
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

  action_item :edit, only: :index do
    link_to 'Notify All Users', notify_users_admin_users_path
  end

end
