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
Returns all users (excluding performers) with associated events.

**Response:**
```json
[
  {
    "id": "user_id",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "123-456-7890",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z",
    "events": [
      {
        "id": "event_id_1",
        "title": "DJ Night",
        "date": "2024-01-15T20:00:00Z",
        "location": "Club XYZ",
        "description": "Amazing DJ event"
      },
      {
        "id": "event_id_2",
        "title": "Summer Festival",
        "date": "2024-07-15T18:00:00Z",
        "location": "Central Park",
        "description": "Outdoor music festival"
      }
    ],
    "tips": []
  }
]
```

#### GET /api/v1/users/:id
Returns a specific user with associated events.

#### POST /api/v1/users
Creates a new user and associates them with events.

**Request Body:**
```json
{
  "user": {
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "123-456-7890",
    "password": "password123",
    "password_confirmation": "password123",
    "event_ids": ["event_id_1", "event_id_2"]
  }
}
```

#### PUT /api/v1/users/:id
Updates an existing user.

#### DELETE /api/v1/users/:id
Deletes a user.

### Performers

**Note:** Performers inherit from Users using Single Table Inheritance (STI). They have all User attributes plus performer-specific fields.

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
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z",
    "events": [
      {
        "id": "event_id_1",
        "title": "DJ Night",
        "date": "2024-01-15T20:00:00Z",
        "location": "Club XYZ",
        "description": "Amazing DJ event"
      },
      {
        "id": "event_id_2",
        "title": "Summer Festival",
        "date": "2024-07-15T18:00:00Z",
        "location": "Central Park",
        "description": "Outdoor music festival"
      }
    ]
  }
]
```

#### GET /api/v1/performers/:id
Returns a specific performer with associated events.

#### POST /api/v1/performers
Creates a new performer and associates them with events.

**Request Body:**
```json
{
  "performer": {
    "name": "DJ Beta",
    "email": "djbeta@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "bio": "Up and coming DJ",
    "genre": "Techno",
    "contact": "djbeta@example.com",
    "event_ids": ["event_id_1", "event_id_2"]
  }
}
```

#### PUT /api/v1/performers/:id
Updates an existing performer.

#### DELETE /api/v1/performers/:id
Deletes a performer.

### Tips

#### GET /api/v1/events/:event_id/tips
Returns all tips for a specific event.

**Response:**
```json
[
  {
    "id": "tip_id",
    "amount": 25.00,
    "message": "Great performance!",
    "created_at": "2024-01-15T22:30:00Z",
    "updated_at": "2024-01-15T22:30:00Z",
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com"
    },
    "event": {
      "id": "event_id",
      "title": "DJ Night",
      "date": "2024-01-15T20:00:00Z",
      "location": "Club XYZ"
    }
  }
]
```

#### GET /api/v1/events/:event_id/tips/:id
Returns a specific tip.

#### POST /api/v1/events/:event_id/tips
Creates a new tip for an event.

**Request Body:**
```json
{
  "tip": {
    "amount": 25.00,
    "message": "Amazing set!",
    "user_id": "user_id"
  }
}
```

#### PUT /api/v1/events/:event_id/tips/:id
Updates an existing tip.

#### DELETE /api/v1/events/:event_id/tips/:id
Deletes a tip.

## Data Model Relationships

### User Model
- **Inheritance**: Performer inherits from User (Single Table Inheritance)
- **Events**: Many-to-many relationship (`has_and_belongs_to_many :events`)
- **Tips**: One-to-many relationship (`has_many :tips`)
- **Scope**: `User.non_performers` returns only regular users (excludes performers)

### Event Model
- **Users**: Many-to-many relationship (`has_and_belongs_to_many :users`)
- **Tips**: One-to-many relationship (`has_many :tips`)
- **Performers**: Custom method that returns users with `_type: 'Performer'`

### Performer Model
- **Inheritance**: Inherits from User model
- **Additional Fields**: `bio`, `genre`, `contact`
- **Events**: Inherited many-to-many relationship from User

### Tip Model
- **User**: Belongs to a user (`belongs_to :user`)
- **Event**: Belongs to an event (`belongs_to :event`)
- **Fields**: `amount`, `message`

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

### Add a User to Multiple Events
```bash
curl -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "Alice Johnson",
      "email": "alice@example.com",
      "phone": "555-0123",
      "password": "password123",
      "password_confirmation": "password123",
      "event_ids": ["EVENT_ID_1", "EVENT_ID_2"]
    }
  }'
```

### Add a Performer to Multiple Events
```bash
curl -X POST http://localhost:3000/api/v1/performers \
  -H "Content-Type: application/json" \
  -d '{
    "performer": {
      "name": "DJ Awesome",
      "email": "djawesome@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "bio": "Electronic music specialist",
      "genre": "Techno",
      "contact": "djawesome@example.com",
      "event_ids": ["EVENT_ID_1", "EVENT_ID_2"]
    }
  }'
```

### Get Event with All Users and Performers
```bash
curl http://localhost:3000/api/v1/events/EVENT_ID_HERE
```

### Create a Tip for an Event
```bash
curl -X POST http://localhost:3000/api/v1/events/EVENT_ID/tips \
  -H "Content-Type: application/json" \
  -d '{
    "tip": {
      "amount": 50.00,
      "message": "Incredible performance tonight!",
      "user_id": "USER_ID_HERE"
    }
  }'
```

## Testing

Run the API integration tests:

```bash
bundle exec rspec spec/requests/api/
```

The test suite includes:
- CRUD operations for all resources (Users, Events, Performers, Tips)
- Many-to-many relationship testing
- Single Table Inheritance (STI) testing
- Error handling and validation
- Content type validation
- Integration workflows
- Cascading delete operations

## Rate Limiting

Currently, there are no rate limits implemented. Consider adding rate limiting for production use.

## Versioning

The API is versioned using URL path versioning (`/api/v1/`). Future versions will be available at `/api/v2/`, etc.
