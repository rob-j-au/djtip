import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search-filter"
export default class extends Controller {
  static targets = ["form", "input", "select"]
  static values = { 
    autoSubmit: Boolean,
    delay: { type: Number, default: 500 }
  }

  connect() {
    this.timeout = null
    if (this.autoSubmitValue) {
      this.setupAutoSubmit()
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  setupAutoSubmit() {
    // Add event listeners to all inputs and selects
    this.inputTargets.forEach(input => {
      input.addEventListener("input", this.scheduleSubmit.bind(this))
    })

    this.selectTargets.forEach(select => {
      select.addEventListener("change", this.submitForm.bind(this))
    })
  }

  scheduleSubmit() {
    // Clear existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Schedule new submission
    this.timeout = setTimeout(() => {
      this.submitForm()
    }, this.delayValue)
  }

  submitForm() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }

    // Add loading state
    this.setLoadingState(true)

    // Submit the form
    this.formTarget.requestSubmit()
  }

  clear() {
    // Clear all form inputs
    this.inputTargets.forEach(input => {
      input.value = ""
    })

    this.selectTargets.forEach(select => {
      select.selectedIndex = 0
    })

    // Submit to clear filters
    this.submitForm()
  }

  setLoadingState(loading) {
    const submitButton = this.formTarget.querySelector('input[type="submit"], button[type="submit"]')
    
    if (loading) {
      if (submitButton) {
        submitButton.classList.add("loading")
        submitButton.disabled = true
      }
    } else {
      if (submitButton) {
        submitButton.classList.remove("loading")
        submitButton.disabled = false
      }
    }
  }
}
