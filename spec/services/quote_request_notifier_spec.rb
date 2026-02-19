require "rails_helper"

RSpec.describe QuoteRequestNotifier do
  describe ".call" do
    let(:vendor) { create(:vendor, phone_number: "+15551234567") }
    let(:mr) { create(:maintenance_request) }
    let(:qr) { create(:quote_request, maintenance_request: mr, vendor: vendor) }

    it "sends an email with the quote link" do
      expect {
        QuoteRequestNotifier.call(qr)
      }.to have_enqueued_mail(VendorNotificationMailer, :sms_simulation)
        .with(vendor.name, a_string_including("quote?token=#{qr.token}"))
    end

    it "includes issue type and severity in the message" do
      expect {
        QuoteRequestNotifier.call(qr)
      }.to have_enqueued_mail(VendorNotificationMailer, :sms_simulation)
        .with(vendor.name, a_string_including(mr.issue_type, mr.severity))
    end

    it "does not send if vendor has no phone number" do
      vendor.update_column(:phone_number, nil)

      expect {
        QuoteRequestNotifier.call(qr)
      }.not_to have_enqueued_mail(VendorNotificationMailer, :sms_simulation)
    end
  end
end
