module ApplicationHelper
  # Formats a phone number string as (XXX) XXX - XXXX
  def format_phone(phone)
    return phone if phone.blank?
    digits = phone.gsub(/\D/, "")
    digits = digits[1..] if digits.start_with?("1") && digits.length == 11
    return phone unless digits.length == 10
    "(#{digits[0..2]}) #{digits[3..5]} - #{digits[6..9]}"
  end
end
