// Keyboard focus for the dynamic room/line-item rows. A new row is inserted before the
// "+ Add" button in DOM order, so without this Tab would skip past it; and hiding a
// removed row drops focus (it was on that row's Remove button) to <body>.

const FIELDS = "input:not([type=hidden]), select, textarea"

export function focusFirstField(row) {
  row?.querySelector(FIELDS)?.focus()
}

// Call *before* hiding `row`: next visible sibling row, else previous, else fallback.
export function focusAfterRemoval(row, rows, fallback) {
  const visible = rows.filter(r => r !== row && !r.classList.contains("hidden"))
  const index = rows.indexOf(row)
  const target = visible.find(r => rows.indexOf(r) > index) || visible.reverse().find(r => rows.indexOf(r) < index)
  if (target) focusFirstField(target)
  else fallback?.focus()
}

export function announce(region, message) {
  if (!region) return
  region.textContent = ""
  requestAnimationFrame(() => { region.textContent = message })
}
