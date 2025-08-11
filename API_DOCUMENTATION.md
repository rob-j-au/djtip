# DJ Tip App REST API Documentation

## Overview

The DJ Tip App provides a comprehensive REST API for managing events, users, and performers. All API endpoints are versioned and return JSON responses.

**Base URL:** `http://localhost:3000/api/v1`

## Authentication

Currently, the API does not require authentication. All endpoints are publicly accessible.

## Content Type

All API requests and responses use `application/json` content type.

## Error Handling

The API returns consistent error responses:

```json
{
  "error": "Error description",
  "details": ["Specific error messages"]
}
```

Common HTTP status codes:
- `200` - Success
- `201` - Created
- `204` - No Content (for successful deletions)
- `404` - Resource not found
- `422` - Validation errors

## Endpoints

### Events

#### GET /api/v1/events
Returns all events with associated users and performers.

**Response:**
```json
[
  {
    "id": "event_id",
    "title": "DJ Night",
    "description": "Amazing DJ event",
    "date": "2024-01-15T20:00:00Z",
    "location": "Club XYZ",
    "users": [
      {
        "id": "user_id",
        "name": "John Doe",
        "email": "john@example.com",
        "phone": "123-456-7890"
      }
    ],
    "performers": [
      {
        "id": "performer_id",
        "name": "DJ Alpha",
        "bio": "Professional DJ",
        "genre": "House",
        "contact": "dj@example.com"
      }
    ]
  }
]
```

#### GET /api/v1/events/:id
Returns a specific event with associated users and performers.

#### POST /api/v1/events
Creates a new event.

**Request Body:**
```json
{
  "event": {
    "title": "New Event",
    "description": "Event description",
    "date": "2024-01-15T20:00:00Z",
    "location": "Event location"
  }
}
```

#### PUT /api/v1/events/:id
Updates an existing event.

#### DELETE /api/v1/events/:id
Deletes an event and all associated users and performers.

### Users

#### GET /api/v1/users
Returns all users with associated events.

**Response:**
```json
[
  {
    "id": "user_id",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "123-456-7890",
    "event": {
      "id": "event_id",
      "title": "DJ Night",
      "date": "2024-01-15T20:00:00Z",
      "location": "Club XYZ"
    }
  }
]
```

#### GET /api/v1/users/:id
Returns a specific user with associated event.

#### POST /api/v1/users
Creates a new user.

**Request Body:**
```json
{
  "user": {
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "123-456-7890",
    "event_id": "event_id"
  }
}
```

#### PUT /api/v1/users/:id
Updates an existing user.

#### DELETE /api/v1/users/:id
Deletes a user.

### Performers

#### GET /api/v1/performers
Returns all performers with associated events.

**Response:**
```json
[
  {
    "id": "performer_id",
    "name": "DJ Alpha",
    "bio": "Professional DJ with 10 years experience",
    "genre": "House",
    "contact": "dj@example.com",
    "event": {
      "id": "event_id",
      "title": "DJ Night",
      "date": "2024-01-15T20:00:00Z",
      "location": "Club XYZ"
    }
  }
]
```

#### GET /api/v1/performers/:id
Returns a specific performer with associated event.

#### POST /api/v1/performers
Creates a new performer.

**Request Body:**
```json
{
  "performer": {
    "name": "DJ Beta",
    "bio": "Up and coming DJ",
    "genre": "Techno",
    "contact": "djbeta@example.com",
    "event_id": "event_id"
  }
}
```

#### PUT /api/v1/performers/:id
Updates an existing performer.

#### DELETE /api/v1/performers/:id
Deletes a performer.

## Example Usage

### Create an Event
```bash
curl -X POST http://localhost:3000/api/v1/events \
  -H "Content-Type: application/json" \
  -d '{
    "event": {
      "title": "Summer DJ Festival",
      "description": "The biggest DJ event of the summer",
      "date": "2024-07-15T18:00:00Z",
      "location": "Central Park"
    }
  }'
```

### Add a User to an Event
```bash
curl -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "Alice Johnson",
      "email": "alice@example.com",
      "phone": "555-0123",
      "event_id": "EVENT_ID_HERE"
    }
  }'
```

### Get Event with All Users and Performers
```bash
curl http://localhost:3000/api/v1/events/EVENT_ID_HERE
```

## Testing

Run the API integration tests:

```bash
bundle exec rspec spec/requests/api/
```

The test suite includes:
- CRUD operations for all resources
- Relationship testing
- Error handling
- Content type validation
- Integration workflows

## Rate Limiting

Currently, there are no rate limits implemented. Consider adding rate limiting for production use.

## Versioning

The API is versioned using URL path versioning (`/api/v1/`). Future versions will be available at `/api/v2/`, etc.
