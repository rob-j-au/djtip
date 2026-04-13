import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["map", "latitude", "longitude", "search"]
  static values = {
    apiKey: String,
    defaultLat: Number,
    defaultLng: Number
  }

  connect() {
    this.loadGoogleMaps()
  }

  loadGoogleMaps() {
    if (window.google && window.google.maps) {
      this.initializeMap()
      return
    }

    const script = document.createElement('script')
    script.src = `https://maps.googleapis.com/maps/api/js?key=${this.apiKeyValue}&libraries=places`
    script.async = true
    script.defer = true
    script.onload = () => this.initializeMap()
    document.head.appendChild(script)
  }

  initializeMap() {
    const lat = this.latitudeTarget.value ? parseFloat(this.latitudeTarget.value) : this.defaultLatValue
    const lng = this.longitudeTarget.value ? parseFloat(this.longitudeTarget.value) : this.defaultLngValue

    const center = { lat, lng }

    this.map = new google.maps.Map(this.mapTarget, {
      center: center,
      zoom: 13,
      mapTypeControl: true,
      streetViewControl: false,
      fullscreenControl: true
    })

    // Create marker
    this.marker = new google.maps.Marker({
      position: center,
      map: this.map,
      draggable: true,
      title: "Performance Location"
    })

    // Update inputs when marker is dragged
    this.marker.addListener('dragend', (event) => {
      this.updateLocation(event.latLng.lat(), event.latLng.lng())
    })

    // Add click listener to map
    this.map.addListener('click', (event) => {
      this.marker.setPosition(event.latLng)
      this.updateLocation(event.latLng.lat(), event.latLng.lng())
    })

    // Initialize autocomplete for address search
    this.initializeAutocomplete()
  }

  initializeAutocomplete() {
    const autocomplete = new google.maps.places.Autocomplete(this.searchTarget, {
      fields: ['geometry', 'name', 'formatted_address']
    })

    autocomplete.addListener('place_changed', () => {
      const place = autocomplete.getPlace()

      if (!place.geometry || !place.geometry.location) {
        alert("No location found for this address")
        return
      }

      const lat = place.geometry.location.lat()
      const lng = place.geometry.location.lng()

      this.map.setCenter({ lat, lng })
      this.marker.setPosition({ lat, lng })
      this.updateLocation(lat, lng)
      this.map.setZoom(15)
    })
  }

  updateLocation(lat, lng) {
    this.latitudeTarget.value = lat.toFixed(6)
    this.longitudeTarget.value = lng.toFixed(6)
  }

  // Manual input handlers
  latitudeChanged() {
    this.updateMarkerFromInputs()
  }

  longitudeChanged() {
    this.updateMarkerFromInputs()
  }

  updateMarkerFromInputs() {
    const lat = parseFloat(this.latitudeTarget.value)
    const lng = parseFloat(this.longitudeTarget.value)

    if (!isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
      const position = { lat, lng }
      this.marker.setPosition(position)
      this.map.setCenter(position)
    }
  }
}
