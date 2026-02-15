require "rails_helper"

RSpec.describe SmsService do
  describe ".send_message" do
    context "when Twilio credentials are missing" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("TWILIO_ACCOUNT_SID").and_return(nil)
      end

      it "logs a warning and returns nil" do
        expect(Rails.logger).to receive(:warn).with(/Twilio credentials missing/)
        result = SmsService.send_message(to: "+15551234567", body: "test")
        expect(result).to be_nil
      end
    end

    context "when Twilio credentials are present" do
      let(:mock_client) { instance_double(Twilio::REST::Client) }
      let(:mock_messages) { double("messages") }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("TWILIO_ACCOUNT_SID").and_return("AC_test")
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:[]).with("TWILIO_AUTH_TOKEN").and_return("token_test")
        allow(ENV).to receive(:[]).with("TWILIO_PHONE_NUMBER").and_return("+15550001111")
        allow(Twilio::REST::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:messages).and_return(mock_messages)
      end

      it "sends an SMS via Twilio" do
        expect(mock_messages).to receive(:create).with(
          from: "+15550001111",
          to: "+15551234567",
          body: "Hello vendor"
        )

        SmsService.send_message(to: "+15551234567", body: "Hello vendor")
      end
    end
  end
end
