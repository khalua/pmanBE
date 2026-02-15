require "rails_helper"

RSpec.describe "Web::Manager::QuoteRequests", type: :request do
  let(:manager) { create(:user, :property_manager) }
  let(:property) { create(:property, property_manager: manager) }
  let(:unit) { create(:unit, property: property) }
  let(:tenant_user) { create(:user, unit: unit) }
  let(:mr) { create(:maintenance_request, tenant: tenant_user) }

  def log_in(user)
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "POST /web/manager/maintenance_requests/:id/quote_requests" do
    it "creates quote requests for selected vendors" do
      allow(SmsService).to receive(:send_message)
      vendors = create_list(:vendor, 2)
      log_in(manager)

      expect {
        post web_manager_maintenance_request_quote_requests_path(mr),
             params: { vendor_ids: vendors.map(&:id) }
      }.to change { QuoteRequest.count }.by(2)

      expect(response).to redirect_to(web_manager_maintenance_request_path(mr))
      expect(mr.reload.status).to eq("vendor_quote_requested")
    end

    it "marks quote requests as sent" do
      allow(SmsService).to receive(:send_message)
      vendors = create_list(:vendor, 2)
      log_in(manager)

      post web_manager_maintenance_request_quote_requests_path(mr),
           params: { vendor_ids: vendors.map(&:id) }

      statuses = QuoteRequest.where(maintenance_request: mr).pluck(:status)
      expect(statuses).to all(eq("sent"))
    end

    it "redirects with alert when no vendors selected" do
      log_in(manager)

      post web_manager_maintenance_request_quote_requests_path(mr), params: { vendor_ids: [] }

      expect(response).to redirect_to(web_manager_maintenance_request_path(mr))
      follow_redirect!
      expect(response.body).to include("No quote requests were created")
    end

    it "skips already-requested vendors" do
      allow(SmsService).to receive(:send_message)
      vendor = create(:vendor)
      create(:quote_request, maintenance_request: mr, vendor: vendor)
      log_in(manager)

      expect {
        post web_manager_maintenance_request_quote_requests_path(mr),
             params: { vendor_ids: [vendor.id] }
      }.not_to change { QuoteRequest.count }
    end

    it "returns 404 for maintenance requests outside manager's properties" do
      other_mr = create(:maintenance_request)
      log_in(manager)

      post web_manager_maintenance_request_quote_requests_path(other_mr),
           params: { vendor_ids: [create(:vendor).id] }
      expect(response).to have_http_status(:not_found)
    end
  end
end
