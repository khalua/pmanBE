require "rails_helper"

RSpec.describe JwtService do
  describe ".encode / .decode" do
    it "encodes and decodes a payload" do
      token = JwtService.encode(user_id: 42)
      decoded = JwtService.decode(token)
      expect(decoded[:user_id]).to eq(42)
    end

    it "returns nil for an expired token" do
      token = JwtService.encode({ user_id: 42 }, 1.second.ago)
      expect(JwtService.decode(token)).to be_nil
    end

    it "returns nil for an invalid token" do
      expect(JwtService.decode("garbage.token.here")).to be_nil
    end
  end
end
