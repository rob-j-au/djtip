import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="table-actions"
export default class extends Controller {
  static targets = ["row", "checkbox", "bulkActions", "selectAll", "counter"]
  static values = { 
    selectedIds: Array,
    totalCount: Number
  }

  connect() {
    this.selectedIdsValue = []
    this.updateUI()
  }

  // Toggle individual row selection
  toggleRow(event) {
    const checkbox = event.currentTarget
    const rowId = checkbox.value
    const row = checkbox.closest('tr')

    if (checkbox.checked) {
      this.selectRow(rowId, row)
    } else {
      this.deselectRow(rowId, row)
    }

    this.updateUI()
  }

  // Select all visible rows
  toggleAll(event) {
    const selectAll = event.currentTarget
    
    this.checkboxTargets.forEach(checkbox => {
      const rowId = checkbox.value
      const row = checkbox.closest('tr')
      
      if (selectAll.checked) {
        checkbox.checked = true
        this.selectRow(rowId, row)
      } else {
        checkbox.checked = false
        this.deselectRow(rowId, row)
      }
    })

    this.updateUI()
  }

  selectRow(rowId, row) {
    if (!this.selectedIdsValue.includes(rowId)) {
      this.selectedIdsValue = [...this.selectedIdsValue, rowId]
    }
    row.classList.add('bg-primary/10', 'border-primary/20')
  }

  deselectRow(rowId, row) {
    this.selectedIdsValue = this.selectedIdsValue.filter(id => id !== rowId)
    row.classList.remove('bg-primary/10', 'border-primary/20')
  }

  updateUI() {
    const selectedCount = this.selectedIdsValue.length
    const totalVisible = this.checkboxTargets.length

    // Update select all checkbox
    if (this.hasSelectAllTarget) {
      if (selectedCount === 0) {
        this.selectAllTarget.checked = false
        this.selectAllTarget.indeterminate = false
      } else if (selectedCount === totalVisible) {
        this.selectAllTarget.checked = true
        this.selectAllTarget.indeterminate = false
      } else {
        this.selectAllTarget.checked = false
        this.selectAllTarget.indeterminate = true
      }
    }

    // Update counter
    if (this.hasCounterTarget) {
      if (selectedCount > 0) {
        this.counterTarget.textContent = `${selectedCount} selected`
        this.counterTarget.classList.remove('hidden')
      } else {
        this.counterTarget.classList.add('hidden')
      }
    }

    // Show/hide bulk actions
    if (this.hasBulkActionsTarget) {
      if (selectedCount > 0) {
        this.bulkActionsTarget.classList.remove('hidden')
      } else {
        this.bulkActionsTarget.classList.add('hidden')
      }
    }

    // Dispatch selection change event
    this.dispatch("selectionChanged", {
      detail: {
        selectedIds: this.selectedIdsValue,
        selectedCount: selectedCount
      }
    })
  }

  // Clear all selections
  clearSelection() {
    this.selectedIdsValue = []
    
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
      const row = checkbox.closest('tr')
      row.classList.remove('bg-primary/10', 'border-primary/20')
    })

    this.updateUI()
  }

  // Bulk delete action
  bulkDelete() {
    if (this.selectedIdsValue.length === 0) return

    const count = this.selectedIdsValue.length
    const message = `Are you sure you want to delete ${count} item${count > 1 ? 's' : ''}?`
    
    if (confirm(message)) {
      this.performBulkAction('delete')
    }
  }

  // Generic bulk action handler
  performBulkAction(action) {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = this.data.get('bulk-url') || '/admin/bulk_actions'

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    // Add action
    const actionInput = document.createElement('input')
    actionInput.type = 'hidden'
    actionInput.name = 'action'
    actionInput.value = action
    form.appendChild(actionInput)

    // Add selected IDs
    this.selectedIdsValue.forEach(id => {
      const idInput = document.createElement('input')
      idInput.type = 'hidden'
      idInput.name = 'ids[]'
      idInput.value = id
      form.appendChild(idInput)
    })

    document.body.appendChild(form)
    form.submit()
  }

  // Export selected items
  exportSelected() {
    if (this.selectedIdsValue.length === 0) return

    const url = new URL(this.data.get('export-url') || '/admin/export')
    this.selectedIdsValue.forEach(id => {
      url.searchParams.append('ids[]', id)
    })

    window.open(url.toString(), '_blank')
  }
}
