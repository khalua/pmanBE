require "rails_helper"

RSpec.describe QuoteApprovalNotifier do
  describe ".call" do
    let(:vendor) { create(:vendor, phone_number: "+15551234567") }
    let(:tenant) { create(:user, :tenant, phone: "+15559876543", email: "tenant@example.com") }
    let(:mr) { create(:maintenance_request, tenant: tenant, issue_type: "kitchen sink leak") }
    let(:quote) { create(:quote, maintenance_request: mr, vendor: vendor) }

    it "sends email to vendor with tenant contact info" do
      expect {
        QuoteApprovalNotifier.call(quote)
      }.to have_enqueued_mail(VendorNotificationMailer, :sms_simulation)
        .with(vendor.name, a_string_including("contact the tenant as soon as possible", tenant.name, tenant.phone, tenant.email))
    end

    it "sends push notification to tenant" do
      allow(PushNotificationService).to receive(:notify)
      QuoteApprovalNotifier.call(quote)
      expect(PushNotificationService).to have_received(:notify).with(
        hash_including(user: tenant, title: "Vendor Assigned")
      )
    end

    it "does not send vendor email if vendor has no phone number" do
      vendor.update!(phone_number: nil)
      allow(PushNotificationService).to receive(:notify)
      expect {
        QuoteApprovalNotifier.call(quote)
      }.not_to have_enqueued_mail(VendorNotificationMailer, :sms_simulation)
    end

    it "still sends tenant push notification even if vendor has no phone" do
      vendor.update!(phone_number: nil)
      allow(PushNotificationService).to receive(:notify)
      QuoteApprovalNotifier.call(quote)
      expect(PushNotificationService).to have_received(:notify)
    end
  end
end
