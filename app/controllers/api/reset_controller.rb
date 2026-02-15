class Api::ResetController < Api::BaseController
  skip_before_action :authenticate_user!

  def create
    Quote.delete_all
    MaintenanceRequest.all.each { |r| r.images.purge }
    MaintenanceRequest.delete_all

    render json: { status: "ok", message: "All requests, quotes, and photos cleared." }
  end
end
