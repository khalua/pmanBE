require "rails_helper"

RSpec.describe QuoteLoserNotifier do
  describe ".call" do
    let(:vendor) { create(:vendor, cell_phone: "+15551234567") }
    let(:mr) { create(:maintenance_request) }
    let(:quote_request) { create(:quote_request, maintenance_request: mr, vendor: vendor) }

    it "sends email to tony.contreras@gmail.com with vendor quote rejection" do
      expect {
        QuoteLoserNotifier.call(quote_request)
      }.to have_enqueued_mail(VendorNotificationMailer, :sms_simulation)
        .with(vendor.name, a_string_including("Thank you for submitting a quote", "another vendor", "hope to work with you"))
    end

    it "does not send email if vendor has no phone number" do
      vendor.update_column(:cell_phone, nil)
      expect {
        QuoteLoserNotifier.call(quote_request)
      }.not_to have_enqueued_mail(VendorNotificationMailer, :sms_simulation)
    end

    it "includes issue type in email" do
      mr.update!(issue_type: "kitchen sink leak")
      expect {
        QuoteLoserNotifier.call(quote_request)
      }.to have_enqueued_mail(VendorNotificationMailer, :sms_simulation)
        .with(vendor.name, a_string_including("kitchen sink leak"))
    end
  end
end
