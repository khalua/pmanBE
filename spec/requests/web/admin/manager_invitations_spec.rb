require "rails_helper"

RSpec.describe "Web::Admin::ManagerInvitations", type: :request do
  let(:admin) { create(:user, :super_admin) }

  def log_in(user)
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /web/admin/manager_invitations" do
    it "lists all manager invitations" do
      invitation = create(:manager_invitation, created_by: admin, manager_name: "Alice Johnson")
      log_in(admin)

      get web_admin_manager_invitations_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Alice Johnson")
      expect(response.body).to include(invitation.code)
    end

    it "redirects unauthenticated users" do
      get web_admin_manager_invitations_path
      expect(response).to redirect_to(login_path)
    end

    it "redirects non-super-admins" do
      log_in(create(:user, :property_manager))
      get web_admin_manager_invitations_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /web/admin/manager_invitations" do
    it "creates a manager invitation and sends email" do
      log_in(admin)

      expect {
        post web_admin_manager_invitations_path, params: {
          manager_invitation: { manager_name: "Bob Smith", manager_email: "bob@example.com" }
        }
      }.to change { ManagerInvitation.count }.by(1)
        .and have_enqueued_mail(UserMailer, :manager_invitation)

      expect(response).to redirect_to(web_admin_manager_invitations_path)
      follow_redirect!
      expect(response.body).to include("Invitation created")
    end

    it "shows errors for invalid params" do
      log_in(admin)

      post web_admin_manager_invitations_path, params: {
        manager_invitation: { manager_name: "", manager_email: "bob@example.com" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "redirects non-super-admins" do
      log_in(create(:user, :property_manager))
      post web_admin_manager_invitations_path, params: {
        manager_invitation: { manager_name: "Bob", manager_email: "bob@example.com" }
      }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /web/admin/manager_invitations/:id/revoke" do
    it "revokes an invitation" do
      invitation = create(:manager_invitation, created_by: admin)
      log_in(admin)

      post revoke_web_admin_manager_invitation_path(invitation)

      expect(response).to redirect_to(web_admin_manager_invitations_path)
      expect(invitation.reload.active).to be false
    end
  end
end
