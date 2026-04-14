# Google Maps API Setup Guide

This guide will help you set up the Google Maps API for the performance location picker.

## Step 1: Get a Google Maps API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps JavaScript API
   - Places API
   - Geocoding API
4. Go to "Credentials" and create an API key
5. (Optional but recommended) Restrict your API key:
   - Set application restrictions (HTTP referrers for web)
   - Set API restrictions to only the APIs listed above

## Step 2: Set Environment Variable

Add your Google Maps API key to your environment:

### For Development (Local)

Add to `.env` file (create if it doesn't exist):

```
GOOGLE_MAPS_API_KEY=your_api_key_here
```

Or set it in your shell:

```bash
export GOOGLE_MAPS_API_KEY=your_api_key_here
```

### For Production

Set the environment variable in your production environment (Heroku, Railway, etc.):

```bash
# Heroku example
heroku config:set GOOGLE_MAPS_API_KEY=your_api_key_here

# Railway example
# Add it in the Railway dashboard under Variables
```

## Step 3: Install Geocoder Gem

Run:

```bash
bundle install
```

This will install the `geocoder` gem which is used for GeoIP lookup.

## Step 4: (Optional) Get IPInfo API Key

For better GeoIP accuracy in production, sign up for a free API key at [ipinfo.io](https://ipinfo.io).

Add to your environment:

```
IPINFO_API_KEY=your_ipinfo_key_here
```

Then uncomment the line in `config/initializers/geocoder.rb`:

```ruby
api_key: ENV['IPINFO_API_KEY'],
```

## Step 5: Restart Your Server

After setting the environment variables, restart your Rails server:

```bash
bin/dev
```

## Features

The location picker includes:

- **GeoIP Detection**: Automatically centers the map on the user's approximate location
- **Address Search**: Search for any address using Google Places Autocomplete
- **Interactive Map**: Click anywhere on the map to set the performance location
- **Draggable Marker**: Drag the marker to fine-tune the location
- **Manual Input**: Enter coordinates directly if needed
- **Bi-directional Sync**: Changes to coordinates update the map, and vice versa

## Troubleshooting

### Map doesn't load

- Check that `GOOGLE_MAPS_API_KEY` is set correctly
- Verify the Maps JavaScript API is enabled in Google Cloud Console
- Check browser console for errors

### Address search doesn't work

- Verify the Places API is enabled in Google Cloud Console
- Check API key restrictions aren't blocking the request

### GeoIP shows wrong location

- In development, localhost IPs won't geolocate correctly (defaults to Sydney)
- Consider getting an IPInfo API key for better accuracy
- Test in production with real IP addresses
