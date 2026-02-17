class Api::PhoneVerificationsController < Api::BaseController
  def send_code
    verification = current_user.phone_verifications.create!(
      phone_number: current_user.mobile_phone
    )

    # Simulated SMS — log the code instead of sending via Twilio
    Rails.logger.info "[PHONE VERIFICATION] Code for #{current_user.email}: #{verification.code}"

    render json: {
      message: "Verification code sent",
      # Include code in response for demo/testing — remove in production
      demo_code: verification.code
    }
  end

  def confirm
    verification = current_user.phone_verifications
      .where(verified_at: nil)
      .where("expires_at > ?", Time.current)
      .order(created_at: :desc)
      .first

    if verification.nil?
      render json: { error: "No pending verification found. Request a new code." }, status: :not_found
      return
    end

    if verification.code != params[:code]
      render json: { error: "Invalid verification code" }, status: :unprocessable_entity
      return
    end

    verification.update!(verified_at: Time.current)
    current_user.update!(phone_verified: true)

    render json: { message: "Phone number verified successfully" }
  end
end
