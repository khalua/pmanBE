require "rails_helper"

RSpec.describe QuoteLoserNotifier do
  describe ".call" do
    let(:vendor) { create(:vendor, phone_number: "+15551234567") }
    let(:mr) { create(:maintenance_request) }
    let(:quote_request) { create(:quote_request, maintenance_request: mr, vendor: vendor) }

    it "sends SMS to vendor who submitted a quote but wasn't selected" do
      expect(SmsService).to receive(:send_message).with(
        to: vendor.phone_number,
        body: a_string_including("Thank you for submitting a quote", "another vendor", "hope to work with you")
      )
      QuoteLoserNotifier.call(quote_request)
    end

    it "does not send SMS if vendor has no phone number" do
      vendor.update!(phone_number: nil)
      expect(SmsService).not_to receive(:send_message)
      QuoteLoserNotifier.call(quote_request)
    end

    it "includes issue type in SMS" do
      mr.update!(issue_type: "kitchen sink leak")
      expect(SmsService).to receive(:send_message).with(
        to: vendor.phone_number,
        body: a_string_including("kitchen sink leak")
      )
      QuoteLoserNotifier.call(quote_request)
    end
  end
end
