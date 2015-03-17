class LoginAsController < ApplicationController
  before_filter :authenticate_user!, :admin_or_logged_in_as?

  def new
    session[:admin_id] = current_user.id
    user = User.find(params[:user_id])
    user.create_activity :login_as, owner: user, params: { ip: ip, admin: current_user.id }
    sign_in user, bypass: true
    redirect_to root_url
  end

  def destroy
    current_user.create_activity :logout_as, owner: current_user, params: { ip: ip, admin: session[:admin_id] }
    user = User.find(session[:admin_id])
    sign_in :user, user
    session[:admin_id] = nil
    redirect_to admin_users_path, notice: "Logged in back as #{user.full_name}"
  end

  private

  def admin_or_logged_in_as?
    is_admin_user? || logged_in_as?
  end
end
