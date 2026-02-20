module ApplicationHelper
  # Formats a phone number string as (XXX) XXX - XXXX
  def format_phone(phone)
    return phone if phone.blank?
    digits = phone.gsub(/\D/, "")
    digits = digits[1..] if digits.start_with?("1") && digits.length == 11
    return phone unless digits.length == 10
    "(#{digits[0..2]}) #{digits[3..5]} - #{digits[6..9]}"
  end

  # Renders a <time> tag that JS converts to the user's local timezone.
  # format: :date ("Jan 15, 2025"), :datetime ("Jan 15, 2025 3:04 PM"), :short_date ("Jan 15")
  def local_time(time, format: :date)
    return "-" if time.blank?
    fallback = case format
               when :datetime then time.utc.strftime("%b %d, %Y %l:%M %p")
               when :short_date then time.utc.strftime("%b %d")
               when :long_date then time.utc.strftime("%B %d, %Y")
               else time.utc.strftime("%b %d, %Y")
               end
    tag.time(fallback, datetime: time.utc.iso8601, data: { format: format })
  end
end
