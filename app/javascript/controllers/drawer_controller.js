import { Controller } from "@hotwired/stimulus"

// Accessibility layer on top of daisyUI's checkbox-driven drawer
// (app/views/layouts/application.html.erb). The checkbox + <label> pair already
// opens and closes the drawer with zero JS - this controller only adds what
// that pair can't do on its own: focus management, Escape-to-close, and
// aria-expanded on the trigger. Pure progressive enhancement - remove this
// controller (or disable JS) and the drawer still opens and closes.
//
// Scoped to the outer .drawer element, so it covers the checkbox, the
// hamburger trigger (in layouts/_navbar), and the panel (layouts/_sidebar,
// inside drawer-side) as one tree.
export default class extends Controller {
  static targets = [ "checkbox", "trigger", "panel" ]

  connect() {
    this.checkboxTarget.addEventListener("change", this.onToggle)
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    this.checkboxTarget.removeEventListener("change", this.onToggle)
    document.removeEventListener("keydown", this.onKeydown)
  }

  onToggle = () => {
    const open = this.checkboxTarget.checked
    this.triggerTarget.setAttribute("aria-expanded", String(open))

    // >=lg the drawer is a permanent rail (lg:drawer-open), not an overlay -
    // don't steal focus or lock scrolling there.
    if (!this.isOverlay()) return

    document.body.classList.toggle("overflow-hidden", open)
    if (open) {
      this.focusFirstPanelItem()
    } else {
      this.triggerTarget.focus()
    }
  }

  // daisyUI's .drawer-side transitions `visibility` with a transition-delay
  // (see application.css's prefers-reduced-motion override, which turns this
  // transition off entirely) - calling .focus() on a descendant while it's
  // still `visibility: hidden` silently does nothing, so wait for the flip
  // rather than focusing immediately on the `change` event.
  focusFirstPanelItem() {
    const focusFirstLink = () => this.panelTarget.querySelector("a, button")?.focus()

    if (getComputedStyle(this.panelTarget).visibility === "visible") {
      focusFirstLink()
      return
    }

    let done = false
    const finish = () => {
      if (done) return
      done = true
      focusFirstLink()
    }
    this.panelTarget.addEventListener("transitionend", finish, { once: true })
    setTimeout(finish, 400) // fallback if no transition ever fires (e.g. reduced-motion)
  }

  onKeydown = (event) => {
    if (event.key !== "Escape") return
    if (!this.isOverlay() || !this.checkboxTarget.checked) return

    this.checkboxTarget.checked = false
    this.onToggle()
  }

  isOverlay() {
    return !window.matchMedia("(min-width: 1024px)").matches
  }
}
