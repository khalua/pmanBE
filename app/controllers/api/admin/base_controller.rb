class Api::Admin::BaseController < Api::BaseController
  before_action :require_super_admin!

  private

  def require_super_admin!
    render json: { error: "Forbidden" }, status: :forbidden unless current_user&.super_admin?
  end
end
