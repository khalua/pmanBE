class Api::DeviceTokensController < Api::BaseController
  def create
    token = current_user.device_tokens.find_or_initialize_by(token: params[:token])
    token.platform = params[:platform] || "ios"
    if token.save
      render json: { message: "Device registered" }, status: :ok
    else
      render json: { errors: token.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    current_user.device_tokens.where(token: params[:token]).destroy_all
    render json: { message: "Device unregistered" }, status: :ok
  end
end
