class PushNotificationService
  def self.notify(user:, title:, body:, data: {})
    new.notify(user: user, title: title, body: body, data: data)
  end

  def notify(user:, title:, body:, data: {})
    tokens = user.device_tokens.pluck(:token)
    return if tokens.empty?

    credentials_path = ENV["FCM_CREDENTIALS_PATH"]
    if credentials_path.blank?
      Rails.logger.warn("[PushNotificationService] FCM_CREDENTIALS_PATH not configured")
      return
    end

    project_id = ENV.fetch("FCM_PROJECT_ID", "prompt-487517")
    fcm = FCM.new(credentials_path, project_id)
    tokens.each do |token|
      message = {
        token: token,
        notification: { title: title, body: body },
        data: data.transform_values(&:to_s),
        apns: { payload: { aps: { sound: "default" } } }
      }
      response = fcm.send_v1(message)
      Rails.logger.info("[PushNotificationService] Sent to #{token[0..8]}...: #{response[:status_code]}")

      # Clean up invalid tokens
      if [ 404, 400, 401 ].include?(response[:status_code])
        DeviceToken.where(token: token).destroy_all
      end
    rescue => e
      Rails.logger.error("[PushNotificationService] Error: #{e.message}")
    end
  end
end
