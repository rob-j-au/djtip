import { Controller } from "@hotwired/stimulus"

// Handles the structured address form for venues:
// 1. Parses Google Places address_components into individual fields
// 2. Dynamically loads state/province options based on selected country
export default class extends Controller {
  static targets = ["line1", "line2", "city", "state", "country", "postcode"]
  static values = {
    states: Object // { "AU": ["New South Wales", ...], "US": ["California", ...], ... }
  }

  connect() {
    this.populateStateDropdown()
    // Listen for Google Places autocomplete selections from map_picker_controller
    this.element.addEventListener('address:selected', (e) => {
      this.populateFromPlace(e.detail.place)
    })
  }

  // Called by map_picker_controller when a place is selected via Google Places
  populateFromPlace(place) {
    if (!place.address_components) return

    const components = {}
    for (const comp of place.address_components) {
      for (const type of comp.types) {
        components[type] = comp
      }
    }

    // Build street address from street_number + route
    const streetNumber = components.street_number?.long_name || ""
    const route = components.route?.long_name || ""
    const streetParts = [streetNumber, route].filter(Boolean)
    if (this.hasLine1Target) {
      this.line1Target.value = streetParts.join(" ") || (place.name || "")
    }

    // Address line 2 (subpremise, e.g. unit/suite number)
    if (this.hasLine2Target) {
      this.line2Target.value = components.subpremise?.long_name || components.sublocality?.long_name || ""
    }

    // City / suburb / locality
    if (this.hasCityTarget) {
      this.cityTarget.value = components.locality?.long_name
        || components.administrative_area_level_2?.long_name
        || components.postal_town?.long_name
        || ""
    }

    // State / province
    if (this.hasStateTarget && components.administrative_area_level_1) {
      this.stateTarget.value = components.administrative_area_level_1.long_name
    }

    // Country
    if (this.hasCountryTarget && components.country) {
      this.countryTarget.value = components.country.short_name
      this.populateStateDropdown()
    }

    // Postcode / ZIP
    if (this.hasPostcodeTarget) {
      this.postcodeTarget.value = components.postal_code?.long_name || ""
    }
  }

  // When country dropdown changes, update the state options
  countryChanged() {
    this.populateStateDropdown()
  }

  populateStateDropdown() {
    if (!this.hasStateTarget || !this.hasCountryTarget) return

    const countryCode = this.countryTarget.value
    const states = this.statesValue[countryCode]

    if (!states || states.length === 0) {
      // No states for this country — show a text input
      this.stateTarget.outerHTML = `<input type="text"
        name="${this.stateTarget.name}"
        id="${this.stateTarget.id}"
        value="${this.stateTarget.value}"
        placeholder="State / Province"
        class="input input-bordered w-full"
        data-address-form-target="state" />`
      return
    }

    const currentValue = this.stateTarget.value
    let options = '<option value="">Select state / province</option>'
    for (const state of states) {
      const selected = state === currentValue ? " selected" : ""
      options += `<option value="${state}"${selected}>${state}</option>`
    }

    this.stateTarget.outerHTML = `<select
      name="${this.stateTarget.name}"
      id="${this.stateTarget.id}"
      class="select select-bordered w-full"
      data-address-form-target="state"
      data-action="address-form#stateChanged">
      ${options}
    </select>`
  }

  stateChanged() {
    // Noop — placeholder for future state change handling
  }
}
