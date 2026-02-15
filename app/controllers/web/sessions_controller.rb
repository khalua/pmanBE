class Web::SessionsController < WebController
  def new
  end

  def create
    user = User.find_by("LOWER(email) = ?", params[:email]&.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      if user.super_admin?
        redirect_to web_admin_dashboard_path, notice: "Logged in successfully."
      elsif user.property_manager?
        redirect_to web_manager_dashboard_path, notice: "Logged in successfully."
      else
        redirect_to web_tenant_dashboard_path, notice: "Logged in successfully."
      end
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Logged out."
  end
end
