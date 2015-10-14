ActiveAdmin.register User do
  actions :all, except: [:destroy]
  menu priority: 6
  
  permit_params :email, :full_name, :admin, :onapp_user, :onapp_email, :vm_max, :cpu_max,
                :storage_max, :bandwidth_max, :memory_max, :password, :password_confirmation, :suspended

  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # permit_params :list, :of, :attributes, :on, :model
  #
  # or
  #
  # permit_params do
  #  permitted = [:permitted, :attributes]
  #  permitted << :other if resource.something?
  #  permitted
  # end

  index do
    column :id
    column :email
    column :current_sign_in_ip
    column :sign_in_count
    column :full_name
    column :admin
    column :suspended

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

    f.actions
  end

  controller do
    def update
      user = params['user']
      if user && (user['password'].nil? || user['password'].empty?)
        user.delete('password')
        user.delete('password_confirmation')
      end
      update!
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
