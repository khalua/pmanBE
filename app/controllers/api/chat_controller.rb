class Api::ChatController < Api::BaseController
  skip_before_action :authenticate_user!

  def chat
    messages = params[:messages] || []
    extracted_info = (params[:extractedInfo] || {}).to_unsafe_h

    # Safety cutoff: if 6+ assistant responses, force completion with whatever we have
    assistant_count = messages.count { |m| m[:role] == "assistant" }
    if assistant_count >= 6
      issue_type = extracted_info["issueType"].presence || "maintenance issue"
      ready_signal = "READY_FOR_PHOTOS"
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

  def support_chat
    messages = params[:messages] || []
    request_context = (params[:requestContext] || {}).to_unsafe_h
    maintenance_request_id = params[:maintenanceRequestId]

    manager_notes = []
    if maintenance_request_id.present?
      mr = MaintenanceRequest.find_by(id: maintenance_request_id)
      if mr
        manager_notes = mr.notes
          .joins(:user)
          .where(users: { role: :property_manager })
          .order(created_at: :asc)
          .map { |n| { content: n.content, userName: n.user.name } }
      end
    end

    bot_response, options = call_claude_support_chat(messages, request_context, manager_notes)
    json = { response: bot_response }
    json[:options] = options if options.present?
    json[:managerNotes] = manager_notes if messages.empty? && manager_notes.any?
    render json: json
  rescue => e
    Rails.logger.error("Support chat API error: #{e.message}")
    render json: { response: "I'm having trouble right now. Please try again." }
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
      2. Where it is (room + specific area if relevant) — SKIP this if the location is obvious from the issue (e.g. oven/fridge/dishwasher = kitchen, toilet/shower = bathroom, AC/heater = whole unit)
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

      WHEN DONE gathering info, ALWAYS respond with exactly: READY_FOR_PHOTOS
      - Do NOT include any other text when responding with READY_FOR_PHOTOS.

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

  def call_claude_support_chat(messages, request_context, manager_notes = [])
    status = request_context["status"] || "submitted"
    issue_type = request_context["issueType"] || "maintenance issue"
    location = request_context["location"] || "your unit"
    vendor_name = request_context["vendorName"]
    arrival_time = request_context["arrivalTime"]
    estimated_cost = request_context["estimatedCost"]

    status_descriptions = {
      "submitted" => "the request has been received and is being reviewed",
      "vendor_quote_requested" => "we are reaching out to vendors for quotes",
      "quote_received" => "a quote has been received and is pending approval",
      "quote_accepted" => "a vendor has been approved and will be in touch to schedule",
      "quote_rejected" => "the quote was rejected and we are finding another vendor",
      "in_progress" => "the repair is currently in progress",
      "completed" => "the repair has been completed"
    }
    status_description = status_descriptions[status] || "being processed"

    vendor_info = vendor_name ? "Assigned vendor: #{vendor_name}." : "No vendor assigned yet."
    arrival_info = arrival_time ? "Scheduled arrival: #{arrival_time}." : ""
    cost_info = estimated_cost ? "Estimated cost: $#{estimated_cost}." : ""

    system_prompt = <<~PROMPT
      You are a friendly property maintenance support assistant helping a tenant follow up on their existing maintenance request.

      Request details:
      - Issue: #{issue_type} in #{location}
      - Current status: #{status} (meaning: #{status_description})
      - #{vendor_info} #{arrival_info} #{cost_info}

      RULES:
      - Keep responses to 1-2 sentences. Be friendly and direct.
      - You can only share what you know from the request details above. Don't make up information.
      - If asked about status, explain it clearly in plain language.
      - If asked when someone will call, refer to the arrival time if available, or say the vendor will be in touch soon.
      - If you don't know something specific, say so honestly and suggest they contact their property manager.
      - Do NOT help with new maintenance requests — only this existing one.

      When your response naturally has 2-4 good follow-up questions the tenant might want to ask, append on a NEW line:
      OPTIONS:["Option 1","Option 2"]
      Keep options short (1-5 words). Options must be questions or actions the tenant can take — never statements like "Check back soon", "Got it", or "Thanks".
      Only include OPTIONS when they genuinely fit. Omit OPTIONS entirely if there is no clear next question.
    PROMPT

    api_messages = messages.filter_map do |m|
      role = m[:role].to_s
      content = m[:content].to_s
      next if role == "system" || content.blank?
      { role: role, content: content }
    end

    api_messages = ensure_alternating(api_messages) if api_messages.any?

    # Seed the first greeting if no history yet
    if api_messages.empty?
      return greeting_for(status, vendor_name, arrival_time, manager_notes)
    end

    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    response = client.messages.create(
      model: "claude-3-haiku-20240307",
      max_tokens: 200,
      system: system_prompt,
      messages: api_messages
    )

    bot_response = response.content.first.text

    options = nil
    if (options_match = bot_response.match(/OPTIONS:\s*(\[.*?\])/m))
      begin
        options = JSON.parse(options_match[1])
      rescue JSON::ParserError
        # ignore
      end
    end

    bot_response = bot_response.gsub(/OPTIONS:\s*\[.*?\]/m, "").strip
    [ bot_response, options ]
  end

  def greeting_for(status, vendor_name, arrival_time, manager_notes = [])
    # If there are manager notes, lead with that — the iOS client will render them specially
    if manager_notes.any?
      msg = "Hi, I'm Prompt, your maintenance assistant. You have a message from your property manager."
      options = ["Reply to manager", "What's the status?", "I have a question"]
      return [ msg, options ]
    end

    if vendor_name && arrival_time
      msg = "Hi, I'm Prompt, your maintenance assistant. Your repair is scheduled with #{vendor_name} — anything you'd like to know?"
      options = ["When will they call?", "What's the status?", "I have a question"]
    elsif vendor_name
      msg = "Hi, I'm Prompt, your maintenance assistant. #{vendor_name} has been assigned to your request. How can I help?"
      options = ["When will they call?", "What's the status?", "I have a question"]
    else
      msg = "Hi, I'm Prompt, your maintenance assistant. I'm here to help with your maintenance request. What would you like to know?"
      options = ["What's the status?", "What happens next?", "I have a question"]
    end
    [ msg, options ]
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
