class PhoneNumbersController < ApplicationController
  
  def create
    current_user.phone_number = params[:phone_number]
    respond_to do |format|
      begin
        if current_user.save
          SendPhoneVerificationPin.perform_async(current_user.id)
          format.json { render json: current_user.as_json(only: [:email, :phone_number]), status: :ok }
        else
          format.json { render json: { error: current_user.errors.full_messages }, status: :unprocessable_entity }
        end
      rescue StandardError => e
        ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'PhoneNumbersController#create'})
        format.json { render json: { error: ['Server Error'] }, status: :internal_server_error }
      end
    end
  end
  
  def verify
    respond_to do |format|
      begin
        if current_user.phone_verification_pin.to_s == params[:phone_verification_pin].to_s
          current_user.update_attribute :phone_verified_at, Time.now
          Rails.cache.delete(["phone_verification_pin", current_user.id])
          html_content = render_to_string partial: 'billing/add_card/verify_phone'
          format.json { render json: { html_content: html_content }, status: :ok }
        else
          format.json { render json: { error: ['Incorrect PIN'] }, status: :unprocessable_entity }
        end
      rescue StandardError => e
        ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'PhoneNumbersController#verify'})
        format.json { render json: { error: ['Server Error'] }, status: :internal_server_error }
      end
    end
  end
  
  def resend
    respond_to do |format|
      begin
        if !current_user.phone_number.blank? && !current_user.phone_verified?
          SendPhoneVerificationPin.new.perform(current_user.id)
          format.json { render json: current_user.as_json(only: [:email, :phone_number]), status: :ok }
        else
          format.json { render json: { error: ['Invalid request'] }, status: :unprocessable_entity }
        end
      rescue StandardError => e
        ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'PhoneNumbersController#resend'})
        format.json { render json: { error: ['Server Error'] }, status: :internal_server_error }
      end
    end
  end
  
end
