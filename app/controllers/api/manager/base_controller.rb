class Api::Manager::BaseController < Api::BaseController
  before_action :require_property_manager!

  private

  def require_property_manager!
    render json: { error: "Forbidden" }, status: :forbidden unless current_user&.property_manager?
  end
end
