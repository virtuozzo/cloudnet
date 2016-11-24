class UserTasks < BaseTasks
  USERNAME_SIZE = 10
  PASSWORD_SIZE = 16

  def perform(action, user_id)
    user = User.find(user_id)

    squall = Squall::User.new(uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass])
    run_task(action, user, squall)
  end

  def self.total_unbilled_revenue
    User.all.to_a.sum {|u| u.try(:account).try(:used_payg_balance).to_f}
  end

  private

  def create(user, squall)
    acc = generate_user_credentials(user.id, user.full_name).merge(role_ids: [ONAPP_CP[:user_role]], billing_plan_id: ONAPP_CP[:billing_plan])

    response = squall.create(acc)
    user.update!(
      onapp_id: response['user']['id'],
      onapp_user: acc[:login],
      onapp_email: acc[:email],
      onapp_password: acc[:password],
      status: :active
    )

    # Create a Sift Science account for user
    user.create_sift_account
    user.create_sift_login_event
  end

  def update_billing_plan(user, squall)
    params = { billing_plan_id: ONAPP_CP[:billing_plan] }
    squall.edit(user.onapp_id, params)
  end

  def generate_user_credentials(id, full_name)
    begin
      cut_name = full_name.gsub(' ', '-').downcase.tr('^a-z\-', '')[0..USERNAME_SIZE]
      username = "#{cut_name}_#{id}_#{SecureRandom.hex(3)}"
      email    = "#{username}@#{ENV['HOST_DOMAIN']}"
      password = generate_password(PASSWORD_SIZE)
    end while User.where(onapp_user: username).exists?

    { login: username, email: email, password: password }
  end

  def allowable_methods
    super + [:create, :update_billing_plan]
  end

  def generate_password(size)
    symbols = ['&', '(', ')', '*', '%', '$', '!']
    string = ('a'..'z').to_a.sample + ('A'..'Z').to_a.sample + (1..9).to_a.sample.to_s + symbols.sample
    o = [('a'..'z'), ('A'..'Z'), (1..9), (9..1)].map(&:to_a).flatten.concat(symbols)
    string + (0...size - 4).map { o[rand(o.length)] }.join
  end
end
