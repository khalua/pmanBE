class Web::RegistrationsController < WebController
  def new
  end

  def create
    user = User.new(registration_params)

    if user.save
      session[:user_id] = user.id
      redirect_to root_path, notice: "Account created successfully."
    else
      @errors = user.errors
      flash.now[:alert] = user.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.permit(:name, :email, :password, :password_confirmation, :role)
  end
end
