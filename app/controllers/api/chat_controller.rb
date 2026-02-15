class Api::ChatController < Api::BaseController
  skip_before_action :authenticate_user!

  def chat
    messages = params[:messages] || []
    extracted_info = (params[:extractedInfo] || {}).to_unsafe_h

    question_count = messages.count { |msg| msg[:role] == "assistant" && msg[:content]&.include?("?") }

    if question_count >= 5
      return render json: {
        response: "READY_FOR_PHOTOS",
        extractedInfo: {
          issueType: extracted_info["issueType"] || "maintenance issue",
          location: extracted_info["location"] || "property",
          severity: extracted_info["severity"] || "unspecified",
          contactPreference: extracted_info["contactPreference"] || "no"
        }
      }
    end

    all_user_text = messages.select { |m| m[:role] == "user" }.map { |m| m[:content].to_s.downcase }.join(" ")

    # Auto-detect issue types
    if extracted_info["issueType"].blank? || extracted_info["issueType"] == "maintenance issue"
      extracted_info["issueType"] = detect_issue_type(all_user_text)
    end

    # Auto-detect appliance locations
    detect_appliance_location(extracted_info, all_user_text)

    # Auto-detect location from common room names
    if extracted_info["location"].blank?
      extracted_info["location"] = detect_location(all_user_text)
    end

    # Auto-detect severity
    if extracted_info["severity"].blank?
      extracted_info["severity"] = detect_severity(all_user_text)
    end

    has_issue = extracted_info["issueType"].present?
    has_location = extracted_info["location"].present?
    has_severity = extracted_info["severity"].present?

    if (has_issue && has_location && has_severity && extracted_info["contactPreference"].present?) || question_count >= 4
      needs_photos = needs_photos?(extracted_info["issueType"])
      return render json: {
        response: needs_photos ? "READY_FOR_PHOTOS" : "READY_FOR_SUBMISSION",
        extractedInfo: extracted_info
      }
    end

    # Call Claude API
    begin
      bot_response, updated_info = call_claude_chat(messages, extracted_info, question_count, has_issue, has_location, has_severity)
      render json: { response: bot_response, extractedInfo: updated_info }
    rescue => e
      Rails.logger.error("Chat API error: #{e.message}")
      render json: {
        response: "I'm having a bit of trouble right now. Can you tell me about your maintenance issue?",
        extractedInfo: extracted_info
      }
    end
  end

  def summarize
    messages = params[:messages] || []
    extracted_info = (params[:extractedInfo] || {}).to_unsafe_h

    begin
      user_messages = messages.select { |m| m[:role] == "user" }.map { |m| m[:content] }.join(" | ")

      system_message = <<~PROMPT
        You are writing a factual summary for a property manager based ONLY on what the tenant actually said. Do not add any assumptions.

        Tenant said: #{user_messages}
        Extracted info: #{extracted_info.to_json}

        Write a 1-2 sentence summary that includes what problem the tenant reported, where it is, and any severity details.
        Only include what the tenant explicitly stated.
      PROMPT

      client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
      response = client.messages.create(
        model: "claude-3-haiku-20240307",
        max_tokens: 150,
        messages: [{ role: "user", content: system_message }]
      )

      summary = response.content.first.text.strip
      render json: { summary: summary }
    rescue => e
      Rails.logger.error("Summarize error: #{e.message}")
      issue_type = extracted_info["issueType"] || "maintenance issue"
      location = extracted_info["location"] || "property"
      severity = extracted_info["severity"] || "moderate"
      render json: { summary: "Tenant reported a #{issue_type} in the #{location} with #{severity} severity." }
    end
  end

  private

  def detect_issue_type(text)
    case text
    when /leak|leaking|dripping|water damage/ then "leak"
    when /clog|blocked|won't drain|backup/ then "clog"
    when /hole/ then "hole"
    when /crack/ then "crack"
    when /no hot water/ then "no hot water"
    when /no heat|cold/ then "no heat"
    when /pest|bug|ant|mouse|roach|spider/ then "pest problem"
    when /outlet|electrical/ then "electrical problem"
    when /mold/ then "mold"
    when /stain/ then "stain"
    when /broken/ then "broken"
    when /not working/ then "not working"
    end
  end

  def detect_appliance_location(info, text)
    appliance_map = {
      /refrigerator|fridge/ => [ "refrigerator issue", "kitchen refrigerator" ],
      /dishwasher/ => [ "dishwasher issue", "kitchen dishwasher" ],
      /stove|oven|range/ => [ "stove/oven issue", "kitchen stove" ],
      /washer(?!.*dish)/ => [ "washer issue", "laundry room washer" ],
      /dryer/ => [ "dryer issue", "laundry room dryer" ],
      /microwave/ => [ "microwave issue", "kitchen microwave" ],
      /garbage disposal/ => [ "garbage disposal issue", "kitchen garbage disposal" ]
    }

    appliance_map.each do |pattern, (issue, location)|
      if text.match?(pattern)
        info["issueType"] = issue unless info["issueType"]&.include?(issue.split(" ").first)
        info["location"] = location
        break
      end
    end
  end

  def detect_location(text)
    locations = {
      "kitchen" => "kitchen",
      "bathroom" => "bathroom",
      "bedroom" => "bedroom",
      "living room" => "living room",
      "basement" => "basement",
      "laundry" => "laundry room",
      "garage" => "garage",
      "attic" => "attic",
      "hallway" => "hallway",
      "dining room" => "dining room",
      "closet" => "closet",
      "patio" => "patio",
      "balcony" => "balcony"
    }
    locations.each do |keyword, location|
      return location if text.include?(keyword)
    end
    nil
  end

  def detect_severity(text)
    if text.match?(/emergency|urgent|flooding|no heat|no hot water/)
      "emergency"
    elsif text.match?(/severe|bad|getting worse|spread/)
      "severe"
    elsif text.match?(/minor|small|tiny/)
      "minor"
    else
      "unspecified"
    end
  end

  def needs_photos?(issue_type)
    return false if issue_type.blank?
    it = issue_type.downcase
    (it.include?("leak") || it.include?("damage") || it.include?("mold") || it.include?("crack") || it.include?("stain") || it.include?("hole")) &&
      !it.include?("appliance") && !it.include?("stove") && !it.include?("washer") && !it.include?("dryer") && !it.include?("dishwasher") && !it.include?("refrigerator")
  end

  def call_claude_chat(messages, extracted_info, question_count, has_issue, has_location, has_severity)
    conversation_context = messages.map { |m| "#{m[:role]}: #{m[:content]}" }.join("\n")

    missing = []
    missing << "issue type" unless has_issue
    missing << "location" unless has_location
    missing << "severity" unless has_severity
    missing << "contact preference" unless extracted_info["contactPreference"].present?

    system_message = <<~PROMPT
      You are a friendly, sympathetic property maintenance assistant chatting with a tenant. Your job is to naturally gather info about their issue through brief conversation.

      You still need: #{missing.join(", ")}
      Already known: #{extracted_info.select { |_, v| v.present? }.to_json}
      Questions asked so far: #{question_count} (max 4)

      Conversation so far:
      #{conversation_context}

      RULES:
      - Write ONLY the message the tenant will see. No labels, no metadata, no tags, no parenthetical notes.
      - 1-2 sentences max. Sound like a real person, not a form.
      - Be empathetic — say "I'm sorry" or "that sounds frustrating", never "Perfect!" or "Great!"
      - Ask for only ONE missing piece of info per message.
      - For "severity", ask naturally like "How bad is it?" or "Is it an emergency or more of a slow drip?"
      - For "contact preference", ask like "Would it be OK for the plumber to call you directly to schedule?" (use the right service provider type)
      - If all info is gathered, respond with exactly READY_FOR_PHOTOS or READY_FOR_SUBMISSION (nothing else)
      - On a NEW line at the very end, add: EXTRACTED_INFO:{"issueType":"...","location":"...","severity":"...","contactPreference":"..."}
      - The EXTRACTED_INFO line must be separate from your message and will be stripped before showing to the tenant.
    PROMPT

    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    response = client.messages.create(
      model: "claude-3-haiku-20240307",
      max_tokens: 200,
      messages: [{ role: "user", content: system_message }]
    )

    bot_response = response.content.first.text
    updated_info = extracted_info.dup

    # Extract and remove EXTRACTED_INFO JSON from response
    if (match = bot_response.match(/EXTRACTED_INFO:\s*(\{.*?\})/m))
      begin
        new_info = JSON.parse(match[1])
        updated_info.merge!(new_info)
      rescue JSON::ParserError
        # ignore
      end
    end

    # Strip all metadata patterns from user-facing text
    bot_response = bot_response
      .gsub(/EXTRACTED_INFO:\s*\{.*?\}/m, "")
      .gsub(/\((?:ISSUE[ _]TYPE|LOCATION|SEVERITY|CONTACT|STATUS)[^)]*\)/i, "")
      .gsub(/\[(?:ISSUE[ _]TYPE|LOCATION|SEVERITY|CONTACT|STATUS)[^\]]*\]/i, "")
      .strip

    if updated_info["issueType"].present? && updated_info["location"].present? && updated_info["severity"].present? && updated_info["contactPreference"].present?
      bot_response = needs_photos?(updated_info["issueType"]) ? "READY_FOR_PHOTOS" : "READY_FOR_SUBMISSION"
    end

    [ bot_response, updated_info ]
  end
end
