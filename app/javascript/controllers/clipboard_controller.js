import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="clipboard"
export default class extends Controller {
  static targets = ["source", "button"]
  static values = { 
    text: String,
    successMessage: { type: String, default: "Copied!" },
    errorMessage: { type: String, default: "Failed to copy" }
  }

  copy() {
    const text = this.getTextToCopy()
    
    if (navigator.clipboard && window.isSecureContext) {
      // Use modern clipboard API
      navigator.clipboard.writeText(text).then(() => {
        this.showSuccess()
      }).catch(() => {
        this.fallbackCopy(text)
      })
    } else {
      // Fallback for older browsers
      this.fallbackCopy(text)
    }
  }

  fallbackCopy(text) {
    // Create temporary textarea
    const textArea = document.createElement("textarea")
    textArea.value = text
    textArea.style.position = "fixed"
    textArea.style.left = "-999999px"
    textArea.style.top = "-999999px"
    document.body.appendChild(textArea)
    
    textArea.focus()
    textArea.select()
    
    try {
      document.execCommand('copy')
      this.showSuccess()
    } catch (err) {
      this.showError()
    } finally {
      textArea.remove()
    }
  }

  getTextToCopy() {
    if (this.textValue) {
      return this.textValue
    }
    
    if (this.hasSourceTarget) {
      return this.sourceTarget.textContent || this.sourceTarget.value
    }
    
    // Try to get from data attribute
    return this.element.dataset.clipboardText || ""
  }

  showSuccess() {
    this.showFeedback(this.successMessageValue, "success")
  }

  showError() {
    this.showFeedback(this.errorMessageValue, "error")
  }

  showFeedback(message, type) {
    // Update button text temporarily
    if (this.hasButtonTarget) {
      const originalText = this.buttonTarget.textContent
      const originalClass = this.buttonTarget.className
      
      this.buttonTarget.textContent = message
      this.buttonTarget.classList.add(type === "success" ? "btn-success" : "btn-error")
      
      setTimeout(() => {
        this.buttonTarget.textContent = originalText
        this.buttonTarget.className = originalClass
      }, 2000)
    } else {
      // Show toast notification
      this.showToast(message, type)
    }
  }

  showToast(message, type) {
    // Create toast element
    const toast = document.createElement("div")
    toast.className = `alert ${type === "success" ? "alert-success" : "alert-error"} fixed top-4 right-4 z-50 max-w-sm`
    toast.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
        ${type === "success" ? 
          '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />' :
          '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />'
        }
      </svg>
      <span>${message}</span>
    `
    
    document.body.appendChild(toast)
    
    // Remove after 3 seconds
    setTimeout(() => {
      toast.remove()
    }, 3000)
  }
}
