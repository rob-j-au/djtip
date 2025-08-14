import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview"]

  connect() {
    // Create preview container if it doesn't exist
    if (this.previewTargets.length === 0) {
      this.previewTarget = document.createElement('div')
      this.previewTarget.className = 'mt-2'
      this.element.parentNode.insertBefore(this.previewTarget, this.element.nextSibling)
    } else {
      this.previewTarget = this.previewTargets[0]
    }
  }

  preview(event) {
    const file = event.target.files[0]
    if (!file) return

    // Clear previous previews
    this.clearPreviews()

    // Check file type
    if (!file.type.match('image.*')) {
      this.showError('Please select an image file (JPG, PNG, or GIF)')
      return
    }

    // Check file size (5MB)
    if (file.size > 5 * 1024 * 1024) {
      this.showError('File size should be less than 5MB')
      return
    }

    // Create preview
    const reader = new FileReader()
    reader.onload = (e) => {
      const img = document.createElement('img')
      img.src = e.target.result
      img.className = 'w-24 h-24 rounded-full object-cover mt-2'
      this.previewTarget.innerHTML = ''
      this.previewTarget.appendChild(img)
    }
    reader.readAsDataURL(file)
  }

  clearPreviews() {
    this.previewTarget.innerHTML = ''
  }

  showError(message) {
    this.previewTarget.innerHTML = `
      <div class="alert alert-error p-2 text-sm mt-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span>${message}</span>
      </div>
    `
    this.element.value = ''
  }
}
