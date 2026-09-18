import { Controller } from "@hotwired/stimulus"

// Moves keyboard focus to this element as soon as it's connected to the DOM.
// Used on the form-errors summary (shared/_form_errors) so a failed submit's
// re-rendered page lands focus on the error summary instead of silently at
// the top of the document.
export default class extends Controller {
  connect() {
    this.element.focus()
  }
}
