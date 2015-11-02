class KeysController < ApplicationController
  
  def index
    @keys = current_user.keys
  end
  
  def create
    @key = current_user.keys.new(key_params)
    if @key.save
      redirect_to :back, notice: 'SSH key was successfully added'
    else
      redirect_to :back, alert: 'Unable to add SSH key. Please try again.'
    end
  end
  
  def destroy
    @key = current_user.keys.find(params[:id])
    @key.destroy!
    redirect_to :back, notice: 'SSH key was successfully deleted'
  end
  
  private
  
  def key_params
    params.require(:key).permit(:title, :key)
  end
  
end
