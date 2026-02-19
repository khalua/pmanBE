require "rails_helper"

RSpec.describe QuoteRejectionNotifier do
  describe ".call" do
    let(:vendor) { create(:vendor, phone_number: "+15551234567") }
    let(:tenant) { create(:user, :tenant) }
    let(:mr) { create(:maintenance_request, tenant: tenant, issue_type: "broken window") }
    let(:quote) { create(:quote, maintenance_request: mr, vendor: vendor) }

    it "sends email via VendorNotificationMailer (not SMS)" do
      allow(PushNotificationService).to receive(:notify)
      expect {
        QuoteRejectionNotifier.call(quote)
      }.to have_enqueued_mail(VendorNotificationMailer, :sms_simulation)
        .with(vendor.name, a_string_including("another option"))
    end

    it "does not send email if vendor has no phone number" do
      vendor.update!(phone_number: nil)
      expect {
        QuoteRejectionNotifier.call(quote)
      }.not_to have_enqueued_mail(VendorNotificationMailer, :sms_simulation)
    end

    it "sends push notification to tenant about rejection" do
      allow(PushNotificationService).to receive(:notify)
      QuoteRejectionNotifier.call(quote)
      expect(PushNotificationService).to have_received(:notify).with(
        hash_including(user: tenant, title: "Quote Update")
      )
    end
  end
end
