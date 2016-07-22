class PhoneNumbersController < ApplicationController
  
  def create
    current_user.unverified_phone_number = params[:phone_number]
    respond_to do |format|
      begin
        if current_user.save
          PhoneVerify.new.cancel(current_user.phone_verification_id) if current_user.phone_verification_id.present?
          verification = PhoneVerify.new.start current_user.unverified_phone_number_full
          success, response = verification[0], verification[1]
          if success
            current_user.phone_verification_id = response
            format.json { render json: current_user.as_json(only: [:email, :phone_number]), status: :ok }
          else
            format.json { render json: { error: [response] }, status: :unprocessable_entity }
          end
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
        check = PhoneVerify.new.check current_user.phone_verification_id, params[:phone_verification_pin].to_s
        success, response = check[0], check[1]
        if success
          current_user.phone_number = current_user.unverified_phone_number_full
          current_user.phone_verified_at = Time.now
          if current_user.save
            current_user.phone_verification_id = current_user.unverified_phone_number = nil
            current_user.update_sift_account
            html_content = render_to_string partial: 'billing/add_card/verify_phone', locals: {verified: true}
            format.json { render json: { html_content: html_content }, status: :ok }
          else
            format.json { render json: { error: current_user.errors.full_messages }, status: :unprocessable_entity }
          end
        else
          format.json { render json: { error: [response] }, status: :unprocessable_entity }
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
        if current_user.phone_verification_id.present?
          response = PhoneVerify.new.trigger_next current_user.phone_verification_id
          if response
            format.json { render json: current_user.as_json(only: [:email, :phone_number]), status: :ok }
          else
            format.json { render json: { error: ['Attempts to verify this number has failed. Please try alternate number.'] }, status: :unprocessable_entity }
          end
        else
          format.json { render json: { error: ['Invalid request'] }, status: :unprocessable_entity }
        end
      rescue StandardError => e
        ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'PhoneNumbersController#resend'})
        format.json { render json: { error: ['Server Error'] }, status: :internal_server_error }
      end
    end
  end
  
  def reset
    respond_to do |format|
      begin
        html_content = render_to_string partial: 'billing/add_card/verify_phone', locals: {verified: false}
        format.json { render json: { html_content: html_content }, status: :ok }
      rescue StandardError => e
        ErrorLogging.new.track_exception(e, extra: { current_user: current_user, source: 'PhoneNumbersController#reset'})
        format.json { render json: { error: ['Server Error'] }, status: :internal_server_error }
      end
    end
  end
  
end
