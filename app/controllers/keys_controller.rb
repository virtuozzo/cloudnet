class KeysController < ApplicationController
  
  def index
    @keys = current_user.keys
  end
  
  def create
    @key = current_user.keys.new(key_params)
    respond_to do |format|
      begin
        if @key.save
          format.html { redirect_to :back, notice: 'SSH key was successfully added' }
          format.json { render nothing: true, status: :no_content }
          format.js { render action: 'show', status: :created, location: @key }
        else
          format.html { redirect_to :back, alert: 'Please enter title and key' }
          format.json { render json: @key.errors, status: :unprocessable_entity }
          format.js { render json: @key.errors, status: :unprocessable_entity }
        end
      rescue StandardError => e
        ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'KeysController#create'})
        format.html { redirect_to :back, alert: 'Unable to add SSH key. Please try again.' }
        format.json { render json: @key.errors, status: :unprocessable_entity }
        format.js { render json: @key.errors, status: :unprocessable_entity }
      end
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
