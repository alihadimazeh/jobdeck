import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.clickOutside = (e) => {
      if (!this.element.contains(e.target)) this.close()
    }
    document.addEventListener("click", this.clickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.clickOutside)
  }

  toggle() {
    if (this.menuTarget.classList.contains("hidden")) {
      const button = this.element.querySelector("button")
      const rect = button.getBoundingClientRect()

      this.menuTarget.classList.remove("hidden")
      this.menuTarget.style.top = `${rect.bottom + 4}px`
      this.menuTarget.style.left = `${rect.right - this.menuTarget.offsetWidth}px`
    } else {
      this.menuTarget.classList.add("hidden")
    }
  }

  close() {
    this.menuTarget.classList.add("hidden")
  }
}
