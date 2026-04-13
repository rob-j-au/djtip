# frozen_string_literal: true

Geocoder.configure(
  # Geocoding options
  timeout: 3,                 # geocoding service timeout (secs)
  lookup: :ipinfo_io,         # name of geocoding service (symbol)
  ip_lookup: :ipinfo_io,      # name of IP address geocoding service (symbol)
  language: :en,              # ISO-639 language code
  use_https: true,            # use HTTPS for lookup requests? (if supported)

  # API key for ipinfo.io (optional, but recommended for production)
  # Sign up at https://ipinfo.io to get a free API key
  # api_key: ENV['IPINFO_API_KEY'],

  # Cache configuration
  cache: Redis.new,           # cache object (must respond to #[], #[]=, and #del)
  cache_prefix: 'geocoder:',  # prefix (string) to use for all cache keys

  # Exceptions that should not be rescued by default
  # (if you want to implement custom error handling);
  # supports SocketError and Timeout::Error
  always_raise: [],

  # Calculation options
  units: :km,                 # :km for kilometers or :mi for miles
  distances: :linear          # :linear or :spherical
)
