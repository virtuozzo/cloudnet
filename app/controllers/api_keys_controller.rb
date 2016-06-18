class ApiKeysController < ApplicationController
  
  def create
    api_key = current_user.api_keys.new(api_key_params)
    if api_key.save
      redirect_to :back, notice: 'API key was successfully generated'
    else
      redirect_to :back, alert: "Unable to add API key. #{api_key.errors.full_messages.first} "
    end
  end
  
  def toggle_active
    api_key = current_user.api_keys.find(params[:id])
    api_key.toggle! :active
    redirect_to :back, notice: "API key was successfully #{api_key.active ? 'enabled' : 'disabled'}"
  end
  
  def destroy
    api_key = current_user.api_keys.find(params[:id])
    api_key.destroy!
    redirect_to :back, notice: 'API key was successfully removed'
  end
  
  private
  
  def api_key_params
    params.require(:api_key).permit(:title, :active)
  end
  
end
