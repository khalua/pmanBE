require "rails_helper"

RSpec.describe "Api::Chat", type: :request do
  let(:anthropic_client) { instance_double(Anthropic::Client) }
  let(:messages_api) { double("messages") }

  before do
    allow(Anthropic::Client).to receive(:new).and_return(anthropic_client)
    allow(anthropic_client).to receive(:messages).and_return(messages_api)
  end

  describe "POST /api/chat" do
    it "does not require authentication" do
      allow(messages_api).to receive(:create).and_return(
        double(content: [double(text: "What's going on?\nEXTRACTED_INFO:{\"issueType\":\"\",\"location\":\"\",\"severity\":\"\",\"contactPreference\":\"\"}")])
      )

      post "/api/chat", params: { messages: [{ role: "user", content: "my sink is broken" }], extractedInfo: {} }, as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns a response and extractedInfo" do
      allow(messages_api).to receive(:create).and_return(
        double(content: [double(text: "That sounds rough. Where is the sink?\nEXTRACTED_INFO:{\"issueType\":\"plumbing\",\"location\":\"\",\"severity\":\"\",\"contactPreference\":\"\"}")])
      )

      post "/api/chat", params: {
        messages: [{ role: "user", content: "my sink is leaking" }],
        extractedInfo: {}
      }, as: :json

      json = JSON.parse(response.body)
      expect(json["response"]).to include("sink")
      expect(json["extractedInfo"]["issueType"]).to eq("plumbing")
    end

    it "strips EXTRACTED_INFO from the user-facing response" do
      allow(messages_api).to receive(:create).and_return(
        double(content: [double(text: "Got it.\nEXTRACTED_INFO:{\"issueType\":\"leak\",\"location\":\"\",\"severity\":\"\",\"contactPreference\":\"\"}")])
      )

      post "/api/chat", params: { messages: [{ role: "user", content: "water leak" }], extractedInfo: {} }, as: :json

      json = JSON.parse(response.body)
      expect(json["response"]).not_to include("EXTRACTED_INFO")
      expect(json["response"]).to eq("Got it.")
    end

    it "parses and returns OPTIONS when present" do
      allow(messages_api).to receive(:create).and_return(
        double(content: [double(text: "Can a plumber contact you directly?\nOPTIONS:[\"Yes, that's fine\",\"No thanks\"]\nEXTRACTED_INFO:{\"issueType\":\"plumbing\",\"location\":\"kitchen\",\"severity\":\"moderate\",\"contactPreference\":\"\"}")])
      )

      post "/api/chat", params: {
        messages: [{ role: "user", content: "kitchen sink leak" }],
        extractedInfo: { issueType: "plumbing", location: "kitchen" }
      }, as: :json

      json = JSON.parse(response.body)
      expect(json["response"]).not_to include("OPTIONS")
      expect(json["options"]).to eq(["Yes, that's fine", "No thanks"])
    end

    it "does not include options key when OPTIONS not present" do
      allow(messages_api).to receive(:create).and_return(
        double(content: [double(text: "Where is the leak?\nEXTRACTED_INFO:{\"issueType\":\"plumbing\",\"location\":\"\",\"severity\":\"\",\"contactPreference\":\"\"}")])
      )

      post "/api/chat", params: { messages: [{ role: "user", content: "I have a leak" }], extractedInfo: {} }, as: :json

      json = JSON.parse(response.body)
      expect(json).not_to have_key("options")
    end

    it "preserves previously extracted info" do
      allow(messages_api).to receive(:create).and_return(
        double(content: [double(text: "How bad is it?\nEXTRACTED_INFO:{\"issueType\":\"\",\"location\":\"bathroom\",\"severity\":\"\",\"contactPreference\":\"\"}")])
      )

      post "/api/chat", params: {
        messages: [{ role: "user", content: "in the bathroom" }],
        extractedInfo: { issueType: "plumbing" }
      }, as: :json

      json = JSON.parse(response.body)
      expect(json["extractedInfo"]["issueType"]).to eq("plumbing")
      expect(json["extractedInfo"]["location"]).to eq("bathroom")
    end

    it "forces READY_FOR_SUBMISSION after 5 assistant messages" do
      messages = 5.times.flat_map do |i|
        [
          { role: "user", content: "message #{i}" },
          { role: "assistant", content: "reply #{i}" }
        ]
      end

      post "/api/chat", params: {
        messages: messages,
        extractedInfo: { issueType: "leak", location: "kitchen" }
      }, as: :json

      json = JSON.parse(response.body)
      expect(json["response"]).to eq("READY_FOR_SUBMISSION")
      expect(json["extractedInfo"]["issueType"]).to eq("leak")
      expect(json["extractedInfo"]["severity"]).to eq("moderate")
    end

    it "fills in defaults on safety cutoff" do
      messages = 5.times.flat_map do |i|
        [{ role: "user", content: "msg" }, { role: "assistant", content: "reply" }]
      end

      post "/api/chat", params: { messages: messages, extractedInfo: {} }, as: :json

      json = JSON.parse(response.body)
      expect(json["extractedInfo"]["issueType"]).to eq("maintenance issue")
      expect(json["extractedInfo"]["location"]).to eq("unit")
      expect(json["extractedInfo"]["severity"]).to eq("moderate")
      expect(json["extractedInfo"]["contactPreference"]).to eq("no")
    end

    it "returns a fallback response on API error" do
      allow(messages_api).to receive(:create).and_raise(StandardError, "API down")

      post "/api/chat", params: { messages: [{ role: "user", content: "help" }], extractedInfo: {} }, as: :json

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json["response"]).to include("trouble")
    end
  end

  describe "POST /api/summarize" do
    it "returns a summary" do
      allow(messages_api).to receive(:create).and_return(
        double(content: [double(text: "Tenant reported a leaking faucet in the kitchen.")])
      )

      post "/api/summarize", params: {
        messages: [
          { role: "user", content: "my kitchen faucet is leaking" },
          { role: "assistant", content: "How bad is the leak?" }
        ],
        extractedInfo: { issueType: "plumbing", location: "kitchen", severity: "moderate" }
      }, as: :json

      json = JSON.parse(response.body)
      expect(json["summary"]).to include("leaking faucet")
    end

    it "saves chat history when maintenance_request_id is provided" do
      mr = create(:maintenance_request)
      allow(messages_api).to receive(:create).and_return(
        double(content: [double(text: "Summary text.")])
      )

      messages = [{ role: "user", content: "sink broken" }, { role: "assistant", content: "got it" }]

      post "/api/summarize", params: {
        messages: messages,
        extractedInfo: {},
        maintenance_request_id: mr.id
      }, as: :json

      mr.reload
      expect(mr.chat_history).to be_present
      expect(mr.chat_history.length).to eq(2)
    end

    it "returns a fallback summary on API error" do
      allow(messages_api).to receive(:create).and_raise(StandardError, "API down")

      post "/api/summarize", params: {
        messages: [{ role: "user", content: "help" }],
        extractedInfo: { issueType: "electrical", location: "bedroom", severity: "urgent" }
      }, as: :json

      json = JSON.parse(response.body)
      expect(json["summary"]).to include("electrical")
      expect(json["summary"]).to include("bedroom")
      expect(json["summary"]).to include("urgent")
    end
  end
end
