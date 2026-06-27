import { Controller } from "@hotwired/stimulus"

// Displays a Google Map via iframe embed (no API key needed for basic embed)
export default class extends Controller {
  static values = {
    latitude: Number,
    longitude: Number
  }

  connect() {
    const lat = this.latitudeValue
    const lng = this.longitudeValue

    // Google Maps embed via iframe — no API key, no JS API needed
    this.element.innerHTML = `<iframe
      src="https://maps.google.com/maps?q=${lat},${lng}&z=16&output=embed"
      width="100%"
      height="100%"
      style="border:0"
      loading="lazy"
      referrerpolicy="no-referrer-when-downgrade"
      title="Performance location map"></iframe>`
  }
}
