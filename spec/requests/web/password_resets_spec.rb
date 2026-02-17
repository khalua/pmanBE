require "rails_helper"

RSpec.describe "Web::PasswordResets", type: :request do
  describe "POST /forgot_password" do
    it "sends a reset email for a regular user" do
      user = create(:user, :property_manager)
      expect {
        post forgot_password_path, params: { email: user.email }
      }.to have_enqueued_mail(UserMailer, :password_reset)

      expect(response).to redirect_to(login_path)
    end

    it "tells Google-auth users to log in with Google instead" do
      user = create(:user, :property_manager, provider: "google_oauth2", uid: "123", google_auth_enabled: true)
      post forgot_password_path, params: { email: user.email }

      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("Google")
    end

    it "returns the same message for non-existent emails" do
      post forgot_password_path, params: { email: "nobody@example.com" }
      expect(response).to redirect_to(login_path)
    end
  end
end
