require "rails_helper"

RSpec.describe "Web::Manager::Tenants", type: :request do
  let(:manager) { create(:user, :property_manager) }
  let(:property) { create(:property, property_manager: manager) }
  let(:unit) { create(:unit, property: property) }
  let(:tenant_user) { create(:user, unit: unit) }

  def log_in(user)
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /web/manager/tenants/:id" do
    it "shows the tenant details" do
      log_in(manager)
      get web_manager_tenant_path(tenant_user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(tenant_user.name)
      expect(response.body).to include(tenant_user.email)
    end

    it "shows tenant's maintenance requests" do
      mr = create(:maintenance_request, tenant: tenant_user)
      log_in(manager)
      get web_manager_tenant_path(tenant_user)

      expect(response.body).to include(mr.issue_type)
    end

    it "shows active/inactive status" do
      log_in(manager)
      get web_manager_tenant_path(tenant_user)
      expect(response.body).to include("Active")
    end

    it "shows move-out button for active tenants" do
      log_in(manager)
      get web_manager_tenant_path(tenant_user)
      expect(response.body).to include("Move Out")
    end

    it "shows reactivate button for inactive tenants" do
      tenant_user.update!(active: false)
      log_in(manager)
      get web_manager_tenant_path(tenant_user)
      expect(response.body).to include("Reactivate")
      expect(response.body).to include("Inactive")
    end

    it "redirects unauthenticated users" do
      get web_manager_tenant_path(tenant_user)
      expect(response).to redirect_to(login_path)
    end

    it "redirects non-managers" do
      log_in(create(:user))
      get web_manager_tenant_path(tenant_user)
      expect(response).to redirect_to(root_path)
    end

    it "redirects when tenant does not belong to manager's properties" do
      other_tenant = create(:user)
      log_in(manager)
      get web_manager_tenant_path(other_tenant)

      expect(response).to redirect_to(web_manager_dashboard_path)
    end
  end

  describe "POST /web/manager/tenants/:id/move_out" do
    it "deactivates the tenant and sets move-out date" do
      log_in(manager)

      post move_out_web_manager_tenant_path(tenant_user)

      expect(response).to redirect_to(web_manager_tenant_path(tenant_user))
      tenant_user.reload
      expect(tenant_user.active).to be false
      expect(tenant_user.move_out_date).to eq(Date.current)
    end
  end

  describe "POST /web/manager/tenants/:id/activate" do
    it "reactivates the tenant" do
      tenant_user.update!(active: false, move_out_date: Date.current)
      log_in(manager)

      post activate_web_manager_tenant_path(tenant_user)

      expect(response).to redirect_to(web_manager_tenant_path(tenant_user))
      expect(tenant_user.reload.active).to be true
    end
  end
end
