require "rails_helper"

RSpec.describe "Web::Manager::Vendors", type: :request do
  let(:manager) { create(:user, :property_manager) }
  let(:tenant) { create(:user) }

  def log_in(user)
    post login_path, params: { email: user.email, password: "password123" }
  end

  def vendor_params(overrides = {})
    attributes_for(:vendor).merge(overrides)
  end

  describe "GET /web/manager/vendors" do
    it "lists the manager's vendors" do
      vendor = create(:vendor, owner_user_id: manager.id)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      log_in(manager)

      get web_manager_vendors_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(vendor.name)
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

  describe "GET /web/manager/vendors/new" do
    it "renders the new vendor form" do
      log_in(manager)
      get new_web_manager_vendor_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Add New Vendor")
    end
  end

  describe "POST /web/manager/vendors" do
    it "creates a vendor and adds it to the manager's pool" do
      log_in(manager)

      expect {
        post web_manager_vendors_path, params: { vendor: vendor_params }
      }.to change { manager.vendors.count }.by(1)
        .and change { Vendor.count }.by(1)

      expect(response).to redirect_to(web_manager_vendors_path)
      follow_redirect!
      expect(response.body).to include("Vendor created.")
    end

    it "sets the vendor as active by default" do
      log_in(manager)
      post web_manager_vendors_path, params: { vendor: vendor_params }
      pmv = manager.property_manager_vendors.last
      expect(pmv.is_active).to be true
    end

    it "sets owner to the manager" do
      log_in(manager)
      post web_manager_vendors_path, params: { vendor: vendor_params }
      expect(Vendor.last.owner_user_id).to eq(manager.id)
    end

    it "re-renders form on invalid params" do
      log_in(manager)
      post web_manager_vendors_path, params: { vendor: vendor_params(cell_phone: "") }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /web/manager/vendors/:id/edit" do
    it "renders the edit form" do
      vendor = create(:vendor, owner_user_id: manager.id)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      log_in(manager)

      get edit_web_manager_vendor_path(vendor)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(vendor.name)
    end
  end

  describe "PATCH /web/manager/vendors/:id" do
    it "updates the vendor" do
      vendor = create(:vendor, owner_user_id: manager.id)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      log_in(manager)

      patch web_manager_vendor_path(vendor), params: { vendor: { name: "Updated Name" } }
      expect(response).to redirect_to(web_manager_vendor_path(vendor))
      expect(vendor.reload.name).to eq("Updated Name")
    end
  end

  describe "GET /web/manager/vendors/:id" do
    it "shows vendor details and stats" do
      vendor = create(:vendor, owner_user_id: manager.id)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      log_in(manager)

      get web_manager_vendor_path(vendor)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(vendor.name)
      expect(response.body).to include("Quotes Received")
      expect(response.body).to include("Jobs Completed")
    end
  end

  describe "PATCH /web/manager/vendors/:id/toggle_active" do
    it "deactivates an active vendor" do
      vendor = create(:vendor, owner_user_id: manager.id)
      pmv = create(:property_manager_vendor, user: manager, vendor: vendor, is_active: true)
      log_in(manager)

      patch toggle_active_web_manager_vendor_path(vendor)
      expect(pmv.reload.is_active).to be false
      expect(response).to redirect_to(web_manager_vendors_path)
    end

    it "activates an inactive vendor" do
      vendor = create(:vendor, owner_user_id: manager.id)
      pmv = create(:property_manager_vendor, user: manager, vendor: vendor, is_active: false)
      log_in(manager)

      patch toggle_active_web_manager_vendor_path(vendor)
      expect(pmv.reload.is_active).to be true
    end
  end

  describe "DELETE /web/manager/vendors/:id" do
    it "removes a vendor from the pool and destroys owned vendor" do
      vendor = create(:vendor, owner_user_id: manager.id)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      log_in(manager)

      expect {
        delete web_manager_vendor_path(vendor)
      }.to change { manager.vendors.count }.by(-1)
        .and change { Vendor.count }.by(-1)

      expect(response).to redirect_to(web_manager_vendors_path)
    end
  end
end
