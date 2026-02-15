class HealthController < ApplicationController
  def show
    render json: { status: "Server is running" }
  end
end
