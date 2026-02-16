require "rails_helper"

RSpec.describe "Web::Tenant::Profiles", type: :request do
  let(:tenant_user) { create(:user, mobile_phone: "555-0100", home_phone: "555-0200") }

  def log_in(user)
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /web/tenant/profile/edit" do
    it "shows the edit form with email and phone fields" do
      log_in(tenant_user)
      get edit_web_tenant_profile_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(tenant_user.email)
      expect(response.body).to include("Mobile Phone")
      expect(response.body).to include("Home Phone")
    end

    it "does not show name or address fields" do
      log_in(tenant_user)
      get edit_web_tenant_profile_path

      expect(response.body).not_to include('name="user[name]"')
      expect(response.body).not_to include('name="user[address]"')
    end

    it "redirects unauthenticated users" do
      get edit_web_tenant_profile_path
      expect(response).to redirect_to(login_path)
    end

    it "redirects non-tenants" do
      log_in(create(:user, :property_manager))
      get edit_web_tenant_profile_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /web/tenant/profile" do
    it "updates email and phone numbers" do
      log_in(tenant_user)
      patch web_tenant_profile_path, params: { user: { email: "new@example.com", mobile_phone: "555-9999", home_phone: "555-8888" } }

      expect(response).to redirect_to(web_tenant_dashboard_path)
      tenant_user.reload
      expect(tenant_user.email).to eq("new@example.com")
      expect(tenant_user.mobile_phone).to eq("555-9999")
      expect(tenant_user.home_phone).to eq("555-8888")
    end

    it "does not allow updating name or address" do
      original_name = tenant_user.name
      original_address = tenant_user.address
      log_in(tenant_user)
      patch web_tenant_profile_path, params: { user: { name: "Hacker", address: "Hacked St", mobile_phone: "555-1111" } }

      tenant_user.reload
      expect(tenant_user.name).to eq(original_name)
      expect(tenant_user.address).to eq(original_address)
    end

    it "requires mobile phone" do
      log_in(tenant_user)
      patch web_tenant_profile_path, params: { user: { mobile_phone: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "redirects unauthenticated users" do
      patch web_tenant_profile_path, params: { user: { email: "x@x.com" } }
      expect(response).to redirect_to(login_path)
    end
  end
end
