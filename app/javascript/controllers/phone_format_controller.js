import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.format()
    this.element.addEventListener("input", () => this.format())
  }

  format() {
    const input = this.element
    const digits = input.value.replace(/\D/g, "")
    // Strip leading 1 for US numbers
    const normalized = digits.startsWith("1") && digits.length > 10 ? digits.slice(1) : digits
    const len = normalized.length

    let formatted = ""
    if (len === 0) {
      formatted = ""
    } else if (len <= 3) {
      formatted = `(${normalized}`
    } else if (len <= 6) {
      formatted = `(${normalized.slice(0, 3)}) ${normalized.slice(3)}`
    } else {
      formatted = `(${normalized.slice(0, 3)}) ${normalized.slice(3, 6)} - ${normalized.slice(6, 10)}`
    }

    if (input.value !== formatted) {
      input.value = formatted
    }
  }
}
