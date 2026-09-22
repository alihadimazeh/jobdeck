import { Controller } from "@hotwired/stimulus"
import { focusFirstField, focusAfterRemoval, announce } from "controllers/row_focus"

export default class extends Controller {
  static targets = [ "lineItemsContainer", "lineItemTemplate", "lineItemRow", "addLineItemButton", "status" ]

  addLineItem() {
    const content = this.lineItemTemplateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    this.lineItemsContainerTarget.insertAdjacentHTML("beforeend", content)
    focusFirstField(this.lineItemsContainerTarget.lastElementChild)
    announce(this.hasStatusTarget ? this.statusTarget : null, "Line item added")
  }

  removeLineItem(event) {
    const row = event.target.closest("[data-order-form-target~='lineItemRow']")
    row.querySelector("[data-line-destroy]").value = "1"
    focusAfterRemoval(row, this.lineItemRowTargets, this.hasAddLineItemButtonTarget ? this.addLineItemButtonTarget : null)
    row.classList.add("hidden")
    announce(this.hasStatusTarget ? this.statusTarget : null, "Line item removed")
  }

  updateLineItemTotal(event) {
    const row = event.target.closest("[data-order-form-target~='lineItemRow']")
    const qty   = parseFloat(row.querySelector("[data-line-quantity]")?.value)   || 0
    const price = parseFloat(row.querySelector("[data-line-unit-price]")?.value) || 0
    row.querySelector("[data-line-total]").textContent = `$${(qty * price).toFixed(2)}`
  }
}
