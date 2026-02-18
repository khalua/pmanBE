require "rails_helper"

RSpec.describe "Web::Manager::MaintenanceRequests", type: :request do
  let(:manager) { create(:user, :property_manager) }
  let(:property) { create(:property, property_manager: manager) }
  let(:unit) { create(:unit, property: property) }
  let(:tenant_user) { create(:user, unit: unit) }
  let(:mr) { create(:maintenance_request, tenant: tenant_user) }

  def log_in(user)
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /web/manager/maintenance_requests/:id" do
    it "shows the maintenance request details" do
      log_in(manager)
      get web_manager_maintenance_request_path(mr)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(mr.issue_type)
      expect(response.body).to include(tenant_user.name)
    end

    it "shows existing quote requests" do
      vendor = create(:vendor)
      create(:quote_request, maintenance_request: mr, vendor: vendor)
      log_in(manager)

      get web_manager_maintenance_request_path(mr)
      expect(response.body).to include(vendor.name)
    end

    it "shows the quote request form with manager's vendors" do
      vendor = create(:vendor)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      log_in(manager)

      get web_manager_maintenance_request_path(mr)
      expect(response.body).to include("Request Quotes")
      expect(response.body).to include(vendor.name)
    end

    it "redirects unauthenticated users" do
      get web_manager_maintenance_request_path(mr)
      expect(response).to redirect_to(login_path)
    end

    it "redirects non-managers" do
      log_in(create(:user))
      get web_manager_maintenance_request_path(mr)
      expect(response).to redirect_to(root_path)
    end

    it "shows a close request form when not completed" do
      log_in(manager)
      get web_manager_maintenance_request_path(mr)
      expect(response.body).to include("Close Request")
    end
  end

  describe "POST /web/manager/maintenance_requests/:id/close" do
    it "closes the request with a note and redirects" do
      log_in(manager)
      post close_web_manager_maintenance_request_path(mr), params: { content: "Not actionable." }
      expect(response).to redirect_to(web_manager_maintenance_request_path(mr))
      expect(mr.reload.status).to eq("completed")
      expect(mr.notes.last.content).to eq("Not actionable.")
    end

    it "rejects empty notes" do
      log_in(manager)
      post close_web_manager_maintenance_request_path(mr), params: { content: "" }
      expect(response).to redirect_to(web_manager_maintenance_request_path(mr))
      expect(mr.reload.status).not_to eq("completed")
    end
  end

  describe "edge cases" do
    it "returns 404 for requests not belonging to manager's properties" do
      other_mr = create(:maintenance_request)
      log_in(manager)

      get web_manager_maintenance_request_path(other_mr)
      expect(response).to have_http_status(:not_found)
    end
  end
end
