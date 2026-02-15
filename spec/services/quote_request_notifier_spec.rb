require "rails_helper"

RSpec.describe QuoteRequestNotifier do
  describe ".call" do
    let(:vendor) { create(:vendor, phone_number: "+15551234567") }
    let(:mr) { create(:maintenance_request) }
    let(:qr) { create(:quote_request, maintenance_request: mr, vendor: vendor) }

    it "sends an SMS with the quote link" do
      expect(SmsService).to receive(:send_message).with(
        to: "+15551234567",
        body: a_string_including("quote?token=#{qr.token}")
      )

      QuoteRequestNotifier.call(qr)
    end

    it "includes issue type and severity in the message" do
      expect(SmsService).to receive(:send_message).with(
        to: "+15551234567",
        body: a_string_including(mr.issue_type, mr.severity)
      )

      QuoteRequestNotifier.call(qr)
    end

    it "does not send if vendor has no phone number" do
      vendor.update_column(:phone_number, nil)

      expect(SmsService).not_to receive(:send_message)
      QuoteRequestNotifier.call(qr)
    end
  end
end
