import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "lineItemsContainer", "lineItemTemplate", "lineItemRow" ]

  addLineItem() {
    const content = this.lineItemTemplateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    this.lineItemsContainerTarget.insertAdjacentHTML("beforeend", content)
  }

  removeLineItem(event) {
    const row = event.target.closest("[data-order-form-target~='lineItemRow']")
    row.querySelector("[data-line-destroy]").value = "1"
    row.classList.add("hidden")
  }

  updateLineItemTotal(event) {
    const row = event.target.closest("[data-order-form-target~='lineItemRow']")
    const qty   = parseFloat(row.querySelector("[data-line-quantity]")?.value)   || 0
    const price = parseFloat(row.querySelector("[data-line-unit-price]")?.value) || 0
    row.querySelector("[data-line-total]").textContent = `$${(qty * price).toFixed(2)}`
  }
}
