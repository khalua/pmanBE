class Api::ChatController < Api::BaseController
  skip_before_action :authenticate_user!

  def chat
    messages = params[:messages] || []
    extracted_info = (params[:extractedInfo] || {}).to_unsafe_h

    # Safety cutoff: if 6+ assistant responses, force completion with whatever we have
    assistant_count = messages.count { |m| m[:role] == "assistant" }
    if assistant_count >= 6
      issue_type = extracted_info["issueType"].presence || "maintenance issue"
      photo_types = %w[leak mold crack stain hole broken damage water]
      ready_signal = photo_types.any? { |t| issue_type.downcase.include?(t) } ? "READY_FOR_PHOTOS" : "READY_FOR_SUBMISSION"
      return render json: {
        response: ready_signal,
        extractedInfo: {
          "issueType" => issue_type,
          "location" => extracted_info["location"].presence || "unit",
          "severity" => extracted_info["severity"].presence || "moderate",
          "contactPreference" => extracted_info["contactPreference"].presence || "no"
        }
      }
    end

    bot_response, updated_info, options = call_claude_chat(messages, extracted_info, assistant_count)
    json = { response: bot_response, extractedInfo: updated_info }
    json[:options] = options if options.present?
    render json: json
  rescue => e
    Rails.logger.error("Chat API error: #{e.message}")
    render json: {
      response: "I'm having a bit of trouble right now. Can you tell me about your maintenance issue?",
      extractedInfo: extracted_info || {}
    }
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

      if params[:maintenance_request_id].present?
        mr = MaintenanceRequest.find(params[:maintenance_request_id])
        mr.update(chat_history: messages.map(&:to_unsafe_h))
      end

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

  def call_claude_chat(messages, extracted_info, assistant_count)
    system_prompt = <<~PROMPT
      You are a friendly property maintenance assistant chatting with a tenant. Your goal is to understand their issue well enough for a property manager to act on it.

      Gather through natural conversation:
      1. What the issue is (e.g. leak, mold, broken appliance, pest, etc.)
      2. Where it is (room + specific area if relevant)
      3. How severe/urgent it is
      4. Whether a service provider can contact them directly to schedule

      RULES:
      - Keep responses to 1-2 sentences. Sound like a real person, not a form.
      - Be empathetic on your FIRST response only. After that, get to the point.
      - Ask about ONE thing at a time. Combine questions only if they're closely related.
      - Use natural language for severity — "How bad is it?" not "Rate the severity."
      - For contact preference, ask if it's OK for the service provider (plumber, electrician, exterminator, etc.) to call THEM directly to schedule a visit. Never suggest the tenant handle repairs themselves — all issues will be handled by a professional.
      - You decide when you have enough info. Don't ask unnecessary follow-ups if the tenant already gave clear details.
      - If the tenant gives you most info in one message, don't drag it out with extra questions.
      - Do NOT ask more than 5 questions total (not counting the initial greeting). You have asked #{assistant_count} so far. If this is your 5th question, wrap up and move to completion.

      WHEN DONE gathering info, decide if photos would help:
      - Photos ARE useful for: visible damage (leaks, cracks, mold, stains, holes, broken items)
      - Photos are NOT useful for: smells, sounds, temperature issues, appliance malfunctions, pests (usually), electrical issues
      - If photos would help, respond with exactly: READY_FOR_PHOTOS
      - If photos would NOT help, respond with exactly: READY_FOR_SUBMISSION
      - Do NOT include any other text when responding with READY_FOR_PHOTOS or READY_FOR_SUBMISSION.

      When your question has a small set of likely answers (2-4 options), append on a NEW line:
      OPTIONS:["Option 1","Option 2"]
      These will be shown as tappable buttons to the tenant. Keep options short (1-5 words each).
      Only include OPTIONS when the question has clear, distinct choices. Do NOT include OPTIONS for open-ended questions.

      On EVERY response (including READY_FOR_PHOTOS/READY_FOR_SUBMISSION), append on a NEW line:
      EXTRACTED_INFO:{"issueType":"...","location":"...","severity":"...","contactPreference":"..."}
      Use empty string "" for fields you don't know yet. The EXTRACTED_INFO and OPTIONS lines will be stripped before showing to the tenant.

      Already known: #{extracted_info.select { |_, v| v.present? }.to_json}
    PROMPT

    # Build messages array for Claude API
    api_messages = messages.filter_map do |m|
      role = m[:role].to_s
      content = m[:content].to_s
      next if role == "system" || content.blank?
      { role: role, content: content }
    end

    # Ensure messages alternate properly — Claude requires user/assistant alternation
    api_messages = ensure_alternating(api_messages) if api_messages.any?

    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    response = client.messages.create(
      model: "claude-3-haiku-20240307",
      max_tokens: 300,
      system: system_prompt,
      messages: api_messages
    )

    bot_response = response.content.first.text
    updated_info = extracted_info.dup

    # Extract and remove EXTRACTED_INFO JSON from response
    if (match = bot_response.match(/EXTRACTED_INFO:\s*(\{.*?\})/m))
      begin
        new_info = JSON.parse(match[1])
        new_info.each { |k, v| updated_info[k] = v if v.present? }
      rescue JSON::ParserError
        # ignore
      end
    end

    # Extract OPTIONS array from response
    options = nil
    if (options_match = bot_response.match(/OPTIONS:\s*(\[.*?\])/m))
      begin
        options = JSON.parse(options_match[1])
      rescue JSON::ParserError
        # ignore
      end
    end

    # Strip metadata from user-facing text
    bot_response = bot_response
      .gsub(/EXTRACTED_INFO:\s*\{.*?\}/m, "")
      .gsub(/OPTIONS:\s*\[.*?\]/m, "")
      .gsub(/\((?:ISSUE[ _]TYPE|LOCATION|SEVERITY|CONTACT|STATUS)[^)]*\)/i, "")
      .gsub(/\[(?:ISSUE[ _]TYPE|LOCATION|SEVERITY|CONTACT|STATUS)[^\]]*\]/i, "")
      .strip

    [ bot_response, updated_info, options ]
  end

  def ensure_alternating(messages)
    result = []
    messages.each do |msg|
      if result.any? && result.last[:role] == msg[:role]
        result.last[:content] += "\n#{msg[:content]}"
      else
        result << msg.dup
      end
    end
    result
  end
end
