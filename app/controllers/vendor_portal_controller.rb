class VendorPortalController < ApplicationController
  def show
    unless params[:token].present?
      return render plain: "A valid token is required to access this page.", status: :bad_request
    end

    quote_request = QuoteRequest.find_by!(token: params[:token])
    request_id = quote_request.maintenance_request_id
    vendor_id = quote_request.vendor_id
    is_approved = params[:approved] == "true"

    html_path = Rails.root.join("public", "service-vendor-portal.html")
    html = File.read(html_path)

    maintenance_request = MaintenanceRequest.find_by(id: request_id)
    request_data = if maintenance_request
      {
        issueType: maintenance_request.issue_type,
        location: maintenance_request.location,
        severity: maintenance_request.severity,
        address: maintenance_request.tenant&.address || "Address not available",
        tenantContact: "#{maintenance_request.tenant&.name} - #{maintenance_request.tenant&.phone}",
        reportedTime: maintenance_request.created_at.strftime("%B %d, %Y at %I:%M %p")
      }
    else
      {
        issueType: "Loading...",
        location: "Loading...",
        severity: "Loading...",
        address: "Address not available",
        tenantContact: "Contact not available",
        reportedTime: Time.current.strftime("%B %d, %Y at %I:%M %p")
      }
    end

    modified_html = html
      .sub("const requestId = urlParams.get('id') || 'sample-request-123';", "const requestId = '#{request_id}';")
      .sub("const isApproved = false;", "const isApproved = #{is_approved};")
      .sub("const vendorId = null;", "const vendorId = #{vendor_id ? "'#{vendor_id}'" : 'null'};")
      .sub("issueType: 'Kitchen Sink Leak'", "issueType: '#{request_data[:issueType]}'")
      .sub("location: 'Kitchen sink under cabinet'", "location: '#{request_data[:location]}'")
      .sub("severity: 'moderate'", "severity: '#{request_data[:severity]}'")
      .sub("address: '123 Main St, Apt 4B, City, State 12345'", "address: '#{request_data[:address]}'")
      .sub("tenantContact: 'John Doe - (555) 123-4567'", "tenantContact: '#{request_data[:tenantContact]}'")
      .sub("reportedTime: 'Today at 2:30 PM'", "reportedTime: '#{request_data[:reportedTime]}'")

    # Inject photos if available
    if maintenance_request&.images&.attached?
      photo_elements = maintenance_request.images.map.with_index do |image, index|
        url = Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
        "<img src=\"#{url}\" alt=\"Issue photo #{index + 1}\" style=\"width: 150px; height: 150px; object-fit: cover; border-radius: 8px;\">"
      end.join

      modified_html = modified_html.sub(
        /<div class="photo-grid">[\s\S]*?<\/div>/,
        "<div class=\"photo-grid\">#{photo_elements}</div>"
      )
    end

    render html: modified_html.html_safe
  end
end
