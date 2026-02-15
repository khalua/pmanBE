require "rails_helper"

RSpec.describe "Web::Manager::Vendors", type: :request do
  let(:manager) { create(:user, :property_manager) }
  let(:tenant) { create(:user) }

  def log_in(user)
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /web/manager/vendors" do
    it "lists the manager's vendors" do
      vendor = create(:vendor)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      log_in(manager)

      get web_manager_vendors_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(vendor.name)
    end

    it "shows available vendors to add" do
      available = create(:vendor, name: "Available Plumber")
      log_in(manager)

      get web_manager_vendors_path
      expect(response.body).to include("Available Plumber")
    end

    it "redirects unauthenticated users" do
      get web_manager_vendors_path
      expect(response).to redirect_to(login_path)
    end

    it "redirects non-managers" do
      log_in(tenant)
      get web_manager_vendors_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /web/manager/vendors" do
    it "adds a vendor to the manager's pool" do
      vendor = create(:vendor)
      log_in(manager)

      expect {
        post web_manager_vendors_path, params: { vendor_id: vendor.id }
      }.to change { manager.vendors.count }.by(1)

      expect(response).to redirect_to(web_manager_vendors_path)
      follow_redirect!
      expect(response.body).to include("Vendor added.")
    end

    it "rejects duplicate vendor" do
      vendor = create(:vendor)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      log_in(manager)

      expect {
        post web_manager_vendors_path, params: { vendor_id: vendor.id }
      }.not_to change { PropertyManagerVendor.count }

      expect(response).to redirect_to(web_manager_vendors_path)
    end
  end

  describe "DELETE /web/manager/vendors/:id" do
    it "removes a vendor from the pool" do
      vendor = create(:vendor)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      log_in(manager)

      expect {
        delete web_manager_vendor_path(vendor)
      }.to change { manager.vendors.count }.by(-1)

      expect(response).to redirect_to(web_manager_vendors_path)
    end
  end
end
