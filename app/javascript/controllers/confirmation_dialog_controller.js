import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="confirmation-dialog"
export default class extends Controller {
  static targets = ["modal", "title", "message", "confirmButton", "cancelButton"]
  static values = { 
    title: String,
    message: String,
    confirmText: { type: String, default: "Confirm" },
    cancelText: { type: String, default: "Cancel" },
    confirmClass: { type: String, default: "btn-error" },
    destructive: Boolean
  }

  connect() {
    this.pendingAction = null
  }

  // Called when a delete/destructive action is triggered
  confirm(event) {
    event.preventDefault()
    event.stopPropagation()

    // Store the original action for later execution
    this.pendingAction = {
      element: event.currentTarget,
      url: event.currentTarget.href || event.currentTarget.dataset.url,
      method: event.currentTarget.dataset.turboMethod || 'DELETE'
    }

    // Set modal content
    this.titleTarget.textContent = this.titleValue || "Confirm Action"
    this.messageTarget.textContent = this.messageValue || "Are you sure you want to proceed?"
    this.confirmButtonTarget.textContent = this.confirmTextValue
    this.cancelButtonTarget.textContent = this.cancelTextValue

    // Set button styling
    this.confirmButtonTarget.className = `btn ${this.confirmClassValue}`
    
    if (this.destructiveValue) {
      this.confirmButtonTarget.classList.add("btn-error")
    }

    // Show modal
    this.modalTarget.showModal()
  }

  // Execute the pending action
  proceed() {
    if (!this.pendingAction) return

    const { element, url, method } = this.pendingAction

    // Create and submit a form for the action
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = url

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    // Add method override if needed
    if (method !== 'POST') {
      const methodInput = document.createElement('input')
      methodInput.type = 'hidden'
      methodInput.name = '_method'
      methodInput.value = method
      form.appendChild(methodInput)
    }

    // Add Turbo frame if present
    const turboFrame = element.dataset.turboFrame
    if (turboFrame) {
      form.dataset.turboFrame = turboFrame
    }

    // Submit form
    document.body.appendChild(form)
    form.submit()

    // Close modal
    this.cancel()
  }

  // Cancel the action and close modal
  cancel() {
    this.pendingAction = null
    this.modalTarget.close()
  }

  // Close modal when clicking outside
  closeOnOutsideClick(event) {
    if (event.target === this.modalTarget) {
      this.cancel()
    }
  }
}
