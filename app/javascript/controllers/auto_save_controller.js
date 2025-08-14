import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="auto-save"
export default class extends Controller {
  static targets = ["form", "status"]
  static values = { 
    interval: { type: Number, default: 30000 }, // 30 seconds
    url: String,
    enabled: { type: Boolean, default: true }
  }

  connect() {
    this.isDirty = false
    this.isSaving = false
    this.saveTimer = null
    
    if (this.enabledValue) {
      this.setupAutoSave()
    }
  }

  disconnect() {
    this.clearTimer()
  }

  setupAutoSave() {
    // Listen for form changes
    this.formTarget.addEventListener("input", this.markDirty.bind(this))
    this.formTarget.addEventListener("change", this.markDirty.bind(this))
    
    // Start the auto-save timer
    this.startTimer()
    
    // Save before page unload if dirty
    window.addEventListener("beforeunload", this.handleBeforeUnload.bind(this))
  }

  markDirty() {
    if (!this.isDirty) {
      this.isDirty = true
      this.updateStatus("unsaved")
    }
  }

  startTimer() {
    this.clearTimer()
    this.saveTimer = setInterval(() => {
      if (this.isDirty && !this.isSaving) {
        this.save()
      }
    }, this.intervalValue)
  }

  clearTimer() {
    if (this.saveTimer) {
      clearInterval(this.saveTimer)
      this.saveTimer = null
    }
  }

  async save() {
    if (this.isSaving || !this.isDirty) return

    this.isSaving = true
    this.updateStatus("saving")

    try {
      const formData = new FormData(this.formTarget)
      const url = this.urlValue || this.formTarget.action
      
      const response = await fetch(url, {
        method: "PATCH",
        body: formData,
        headers: {
          "X-Requested-With": "XMLHttpRequest",
          "X-CSRF-Token": this.getCSRFToken()
        }
      })

      if (response.ok) {
        this.isDirty = false
        this.updateStatus("saved")
        this.dispatch("saved", { detail: { response } })
      } else {
        throw new Error(`HTTP ${response.status}`)
      }
    } catch (error) {
      console.error("Auto-save failed:", error)
      this.updateStatus("error")
      this.dispatch("error", { detail: { error } })
    } finally {
      this.isSaving = false
    }
  }

  // Manual save trigger
  saveNow() {
    if (this.isDirty) {
      this.save()
    }
  }

  updateStatus(status) {
    if (!this.hasStatusTarget) return

    const messages = {
      unsaved: { text: "Unsaved changes", class: "text-warning" },
      saving: { text: "Saving...", class: "text-info" },
      saved: { text: "All changes saved", class: "text-success" },
      error: { text: "Save failed", class: "text-error" }
    }

    const message = messages[status]
    if (message) {
      this.statusTarget.textContent = message.text
      this.statusTarget.className = `text-sm ${message.class}`
    }

    // Clear success message after delay
    if (status === "saved") {
      setTimeout(() => {
        if (this.hasStatusTarget && !this.isDirty) {
          this.statusTarget.textContent = ""
        }
      }, 3000)
    }
  }

  handleBeforeUnload(event) {
    if (this.isDirty) {
      event.preventDefault()
      event.returnValue = "You have unsaved changes. Are you sure you want to leave?"
      return event.returnValue
    }
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.content : ""
  }

  // Enable/disable auto-save
  toggle() {
    this.enabledValue = !this.enabledValue
    
    if (this.enabledValue) {
      this.startTimer()
    } else {
      this.clearTimer()
    }
  }
}
