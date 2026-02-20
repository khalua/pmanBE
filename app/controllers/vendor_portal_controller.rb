class VendorPortalController < ApplicationController
  before_action :find_quote_request, only: [ :show, :mark_contacted, :mark_work_complete ]

  def show
    request_id = @quote_request.maintenance_request_id
    vendor_id = @quote_request.vendor_id
    is_approved = params[:approved] == "true"
    is_rejected = @quote_request.rejected?
    vendor_contacted = @quote_request.vendor_contacted_at.present?

    html_path = Rails.root.join("public", "service-vendor-portal.html")
    html = File.read(html_path)

    maintenance_request = MaintenanceRequest.find_by(id: request_id)
    request_data = if maintenance_request
      {
        issueType: maintenance_request.issue_type,
        location: maintenance_request.location,
        severity: maintenance_request.severity,
        address: maintenance_request.tenant&.unit&.property&.address || maintenance_request.tenant&.address || "Address not available",
        tenantContact: "#{maintenance_request.tenant&.name} - #{maintenance_request.tenant&.phone}",
        reportedTime: maintenance_request.created_at.strftime("%B %d, %Y at %I:%M %p"),
        tenantAvailableTime: maintenance_request.tenant_available_time
      }
    else
      {
        issueType: "Loading...",
        location: "Loading...",
        severity: "Loading...",
        address: "Address not available",
        tenantContact: "Contact not available",
        reportedTime: Time.current.strftime("%B %d, %Y at %I:%M %p"),
        tenantAvailableTime: nil
      }
    end

    tenant_time_js = request_data[:tenantAvailableTime] ? "'#{request_data[:tenantAvailableTime]}'" : "null"

    modified_html = html
      .sub("const requestId = urlParams.get('id') || 'sample-request-123';", "const requestId = '#{request_id}';")
      .sub("const isApproved = false;", "const isApproved = #{is_approved};")
      .sub("const isRejected = false;", "const isRejected = #{is_rejected};")
      .sub("const vendorContacted = false;", "const vendorContacted = #{vendor_contacted};")
      .sub("const vendorToken = null;", "const vendorToken = '#{@quote_request.token}';")
      .sub("const vendorId = null;", "const vendorId = #{vendor_id ? "'#{vendor_id}'" : 'null'};")
      .sub("const tenantAvailableTime = null;", "const tenantAvailableTime = #{tenant_time_js};")
      .sub("issueType: 'Kitchen Sink Leak'", "issueType: '#{request_data[:issueType]}'")
      .sub("location: 'Kitchen sink under cabinet'", "location: '#{request_data[:location]}'")
      .sub("severity: 'moderate'", "severity: '#{request_data[:severity]}'")
      .sub("address: '123 Main St, Apt 4B, City, State 12345'", "address: '#{request_data[:address]}'")
      .sub("tenantContact: 'John Doe - (555) 123-4567'", "tenantContact: '#{request_data[:tenantContact]}'")
      .sub("reportedTime: 'Today at 2:30 PM'", "reportedTime: '#{request_data[:reportedTime]}'")

    # Inject photos if available, otherwise hide the section entirely
    if maintenance_request&.images&.attached?
      photo_elements = maintenance_request.images.map.with_index do |image, index|
        url = Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
        "<img src=\"#{url}\" alt=\"Issue photo #{index + 1}\" style=\"width: 150px; height: 150px; object-fit: cover; border-radius: 8px;\">"
      end.join

      modified_html = modified_html.sub(
        /<div class="photo-grid">[\s\S]*?<\/div>\s*<\/div>/,
        "<div class=\"photo-grid\">#{photo_elements}</div>"
      )
    else
      modified_html = modified_html.sub(
        /<!-- PHOTOS_SECTION_START -->[\s\S]*?<!-- PHOTOS_SECTION_END -->/,
        ""
      )
    end

    render html: modified_html.html_safe
  end

  def mark_contacted
    if @quote_request.vendor_contacted_at.present?
      return render json: { ok: true, already: true }
    end

    @quote_request.update!(vendor_contacted_at: Time.current)

    mr = @quote_request.maintenance_request
    VendorContactedNotifier.call(@quote_request)

    render json: { ok: true }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def mark_work_complete
    unless @quote_request.vendor_contacted_at.present?
      return render json: { error: "Please mark that you've contacted the tenant first." }, status: :unprocessable_entity
    end

    @quote_request.update!(vendor_work_completed_at: Time.current)

    mr = @quote_request.maintenance_request
    mr.update!(status: :completed)

    VendorWorkCompleteNotifier.call(@quote_request)

    render json: { ok: true }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def find_quote_request
    unless params[:token].present?
      return render plain: "A valid token is required to access this page.", status: :bad_request
    end
    @quote_request = QuoteRequest.find_by!(token: params[:token])
  end
end
