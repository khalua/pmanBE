class SmsService
  def self.send_message(to:, body:)
    account_sid = ENV["TWILIO_ACCOUNT_SID"]
    auth_token = ENV["TWILIO_AUTH_TOKEN"]
    from_number = ENV["TWILIO_PHONE_NUMBER"]

    if account_sid.blank? || auth_token.blank?
      Rails.logger.warn("[SmsService] Twilio credentials missing — skipping SMS to #{to}")
      return nil
    end

    client = Twilio::REST::Client.new(account_sid, auth_token)
    client.messages.create(from: from_number, to: to, body: body)
  end
end
