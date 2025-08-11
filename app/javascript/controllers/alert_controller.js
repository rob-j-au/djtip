import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="alert"
export default class extends Controller {
  dismiss() {
    this.element.remove()
  }
}
