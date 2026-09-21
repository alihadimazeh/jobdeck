import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "roomsContainer", "roomTemplate", "roomRow",
    "lineItemsContainer", "lineItemTemplate", "lineItemRow",
    "totalArea", "laborRate", "materialRate"
  ]

  // Rooms

  addRoom() {
    const content = this.roomTemplateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    this.roomsContainerTarget.insertAdjacentHTML("beforeend", content)
  }

  removeRoom(event) {
    const row = event.target.closest("[data-quote-form-target~='roomRow']")
    row.querySelector("[data-room-destroy]").value = "1"
    row.classList.add("hidden")
    this.#refreshTotalArea()
  }

  updateRoomArea(event) {
    const row = event.target.closest("[data-quote-form-target~='roomRow']")
    const length = parseFloat(row.querySelector("[data-room-length]")?.value) || 0
    const width  = parseFloat(row.querySelector("[data-room-width]")?.value)  || 0
    const area   = length * width
    row.querySelector("[data-room-area]").textContent = area > 0 ? area.toFixed(2) : "—"
    this.#refreshTotalArea()
  }

  // Line items

  addLineItem() {
    const content = this.lineItemTemplateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    this.lineItemsContainerTarget.insertAdjacentHTML("beforeend", content)
  }

  removeLineItem(event) {
    const row = event.target.closest("[data-quote-form-target~='lineItemRow']")
    row.querySelector("[data-line-destroy]").value = "1"
    row.classList.add("hidden")
  }

  updateLineItemTotal(event) {
    const row = event.target.closest("[data-quote-form-target~='lineItemRow']")
    this.#recalcLineItem(row)
  }

  // Estimation tool

  populateLineItems() {
    const area = parseFloat(this.totalAreaTarget.textContent) || 0
    if (area <= 0) return

    const laborRate    = parseFloat(this.laborRateTarget.value)    || 0
    const materialRate = parseFloat(this.materialRateTarget.value) || 0
    if (laborRate <= 0 && materialRate <= 0) return

    this.lineItemRowTargets.forEach(row => {
      row.querySelector("[data-line-destroy]").value = "1"
      row.classList.add("hidden")
    })

    if (laborRate > 0)    this.#addLineItemWithValues("labor",    "Labour",    area, "sqft", laborRate)
    if (materialRate > 0) this.#addLineItemWithValues("material", "Materials", area, "sqft", materialRate)
  }

  // Private

  #refreshTotalArea() {
    let total = 0
    this.roomRowTargets.forEach(row => {
      if (row.classList.contains("hidden")) return
      const length = parseFloat(row.querySelector("[data-room-length]")?.value) || 0
      const width  = parseFloat(row.querySelector("[data-room-width]")?.value)  || 0
      total += length * width
    })
    this.totalAreaTarget.textContent = total > 0 ? total.toFixed(2) : "0"
  }

  #recalcLineItem(row) {
    const qty   = parseFloat(row.querySelector("[data-line-quantity]")?.value)   || 0
    const price = parseFloat(row.querySelector("[data-line-unit-price]")?.value) || 0
    row.querySelector("[data-line-total]").textContent = `$${(qty * price).toFixed(2)}`
  }

  #addLineItemWithValues(itemType, description, quantity, unit, unitPrice) {
    const content = this.lineItemTemplateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    this.lineItemsContainerTarget.insertAdjacentHTML("beforeend", content)
    const row = this.lineItemsContainerTarget.lastElementChild
    row.querySelector("[data-line-type]").value      = itemType
    row.querySelector("[data-line-description]").value = description
    row.querySelector("[data-line-quantity]").value  = quantity.toFixed(2)
    row.querySelector("[data-line-unit]").value      = unit
    row.querySelector("[data-line-unit-price]").value = unitPrice.toFixed(2)
    row.querySelector("[data-line-total]").textContent = `$${(quantity * unitPrice).toFixed(2)}`
  }
}
