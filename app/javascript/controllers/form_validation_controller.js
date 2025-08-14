import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-validation"
export default class extends Controller {
  static targets = ["field", "error", "submit"]
  static classes = ["invalid", "valid"]

  connect() {
    this.setupValidation()
  }

  setupValidation() {
    this.fieldTargets.forEach(field => {
      field.addEventListener("blur", () => this.validateField(field))
      field.addEventListener("input", () => this.clearFieldError(field))
    })

    // Validate on form submit
    this.element.addEventListener("submit", this.validateForm.bind(this))
  }

  validateField(field) {
    const isValid = this.checkFieldValidity(field)
    this.updateFieldState(field, isValid)
    return isValid
  }

  validateForm(event) {
    let isFormValid = true

    this.fieldTargets.forEach(field => {
      const isFieldValid = this.validateField(field)
      if (!isFieldValid) {
        isFormValid = false
      }
    })

    if (!isFormValid) {
      event.preventDefault()
      this.showFormErrors()
    }

    return isFormValid
  }

  checkFieldValidity(field) {
    // Check HTML5 validity
    if (!field.checkValidity()) {
      return false
    }

    // Custom validation rules
    const fieldType = field.type || field.tagName.toLowerCase()
    const value = field.value.trim()

    switch (fieldType) {
      case 'email':
        return this.validateEmail(value)
      case 'tel':
      case 'phone':
        return this.validatePhone(value)
      case 'url':
        return this.validateUrl(value)
      case 'number':
        return this.validateNumber(field)
      case 'date':
      case 'datetime-local':
        return this.validateDate(field)
      default:
        return true
    }
  }

  validateEmail(email) {
    if (!email) return true // Allow empty if not required
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
  }

  validatePhone(phone) {
    if (!phone) return true // Allow empty if not required
    // Basic phone validation - adjust as needed
    const phoneRegex = /^[\+]?[1-9][\d]{0,15}$/
    return phoneRegex.test(phone.replace(/[\s\-\(\)]/g, ''))
  }

  validateUrl(url) {
    if (!url) return true // Allow empty if not required
    try {
      new URL(url)
      return true
    } catch {
      return false
    }
  }

  validateNumber(field) {
    const value = parseFloat(field.value)
    const min = field.min ? parseFloat(field.min) : null
    const max = field.max ? parseFloat(field.max) : null

    if (isNaN(value)) return !field.required

    if (min !== null && value < min) return false
    if (max !== null && value > max) return false

    return true
  }

  validateDate(field) {
    if (!field.value) return !field.required
    
    const date = new Date(field.value)
    if (isNaN(date.getTime())) return false

    // Check min/max dates if specified
    if (field.min && date < new Date(field.min)) return false
    if (field.max && date > new Date(field.max)) return false

    return true
  }

  updateFieldState(field, isValid) {
    const fieldContainer = field.closest('.form-control') || field.parentElement
    
    if (isValid) {
      field.classList.remove(this.invalidClass)
      field.classList.add(this.validClass)
      fieldContainer.classList.remove('has-error')
      this.hideFieldError(field)
    } else {
      field.classList.remove(this.validClass)
      field.classList.add(this.invalidClass)
      fieldContainer.classList.add('has-error')
      this.showFieldError(field)
    }
  }

  clearFieldError(field) {
    field.classList.remove(this.invalidClass, this.validClass)
    const fieldContainer = field.closest('.form-control') || field.parentElement
    fieldContainer.classList.remove('has-error')
    this.hideFieldError(field)
  }

  showFieldError(field) {
    const errorElement = this.findErrorElement(field)
    if (errorElement) {
      errorElement.textContent = this.getFieldErrorMessage(field)
      errorElement.classList.remove('hidden')
    }
  }

  hideFieldError(field) {
    const errorElement = this.findErrorElement(field)
    if (errorElement) {
      errorElement.classList.add('hidden')
    }
  }

  findErrorElement(field) {
    // Look for error element by data attribute or class
    const fieldContainer = field.closest('.form-control') || field.parentElement
    return fieldContainer.querySelector('[data-field-error]') || 
           fieldContainer.querySelector('.field-error') ||
           fieldContainer.querySelector('.error-message')
  }

  getFieldErrorMessage(field) {
    if (field.dataset.errorMessage) {
      return field.dataset.errorMessage
    }

    // Default error messages
    if (field.validity.valueMissing) {
      return `${this.getFieldLabel(field)} is required`
    }
    if (field.validity.typeMismatch) {
      return `Please enter a valid ${field.type}`
    }
    if (field.validity.tooShort) {
      return `${this.getFieldLabel(field)} must be at least ${field.minLength} characters`
    }
    if (field.validity.tooLong) {
      return `${this.getFieldLabel(field)} must be no more than ${field.maxLength} characters`
    }
    if (field.validity.rangeUnderflow) {
      return `${this.getFieldLabel(field)} must be at least ${field.min}`
    }
    if (field.validity.rangeOverflow) {
      return `${this.getFieldLabel(field)} must be no more than ${field.max}`
    }

    return `${this.getFieldLabel(field)} is invalid`
  }

  getFieldLabel(field) {
    const label = field.closest('.form-control')?.querySelector('label')
    return label?.textContent?.replace('*', '').trim() || field.name || 'Field'
  }

  showFormErrors() {
    // Scroll to first error
    const firstError = this.element.querySelector(`.${this.invalidClass}`)
    if (firstError) {
      firstError.scrollIntoView({ behavior: 'smooth', block: 'center' })
      firstError.focus()
    }
  }
}
