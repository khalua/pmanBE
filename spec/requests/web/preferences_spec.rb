require "rails_helper"

RSpec.describe "Web::Preferences", type: :request do
  def log_in(user)
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /preferences" do
    it "requires authentication" do
      get web_preferences_path
      expect(response).to redirect_to(login_path)
    end

    it "shows the preferences page" do
      user = create(:user, :property_manager)
      log_in(user)
      get web_preferences_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Preferences")
    end

    it "shows Google auth toggle for Gmail users" do
      user = create(:user, :property_manager, email: "pm@gmail.com")
      log_in(user)
      get web_preferences_path
      expect(response.body).to include("Google")
    end

    it "does not show Google auth toggle for non-Gmail users" do
      user = create(:user, :property_manager, email: "pm@outlook.com")
      log_in(user)
      get web_preferences_path
      expect(response.body).not_to include("Enable Google login")
    end
  end

  describe "PATCH /preferences" do
    it "enables Google auth for Gmail users" do
      user = create(:user, :property_manager, email: "pm@gmail.com")
      log_in(user)
      patch web_preferences_path, params: { google_auth_enabled: "1" }

      expect(user.reload.google_auth_enabled).to be true
      expect(response).to redirect_to(web_preferences_path)
    end

    it "disables Google auth" do
      user = create(:user, :property_manager, email: "pm@gmail.com", google_auth_enabled: true)
      log_in(user)
      patch web_preferences_path, params: { google_auth_enabled: "0" }

      expect(user.reload.google_auth_enabled).to be false
    end

    it "rejects Google auth for non-Gmail users" do
      user = create(:user, :property_manager, email: "pm@outlook.com")
      log_in(user)
      patch web_preferences_path, params: { google_auth_enabled: "1" }

      expect(user.reload.google_auth_enabled).to be false
    end
  end
end
