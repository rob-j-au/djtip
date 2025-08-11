# DJ Tip App

A Ruby on Rails 8 application using Mongoid (MongoDB) instead of ActiveRecord, with Bootstrap styling for managing events, users, and performers.

## Features

- **Events Management**: Create and manage events with title, description, date, and location
- **Users Management**: Register users for events with contact information
- **Performers Management**: Add performers to events with bio and genre information
- **Relationships**: Events can have multiple users and performers
- **Bootstrap UI**: Modern, responsive design with Bootstrap 5.3
- **MongoDB**: Uses Mongoid ODM instead of ActiveRecord

## Models

### Event
- `title` (String) - Event name
- `description` (String) - Event description
- `date` (DateTime) - Event date and time
- `location` (String) - Event location
- **Relationships**: `has_many :users`, `has_many :performers`

### User
- `name` (String) - User's full name
- `email` (String) - User's email address
- `phone` (String) - User's phone number
- **Relationships**: `belongs_to :event` (optional)

### Performer
- `name` (String) - Performer's name
- `bio` (String) - Performer's biography
- `genre` (String) - Music genre
- `contact` (String) - Contact information
- **Relationships**: `belongs_to :event` (optional)

## Setup Instructions

### Prerequisites
- Ruby 3.2.0 or higher
- MongoDB installed and running
- Bundler gem

### Installation

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Start MongoDB:**
   ```bash
   # On macOS with Homebrew:
   brew services start mongodb-community
   
   # Or manually:
   mongod
   ```

3. **Start the Rails server:**
   ```bash
   rails server
   ```

4. **Visit the application:**
   Open your browser and go to `http://localhost:3000`

## Usage

1. **Create Events**: Start by creating events from the main page
2. **Add Users**: Register users and optionally assign them to events
3. **Add Performers**: Add performers and assign them to events
4. **Manage Relationships**: View events to see associated users and performers

## Development

### Database Configuration

The app uses MongoDB with the following databases:
- Development: `djtip_development`
- Test: `djtip_test`
- Production: Uses `MONGODB_URI` environment variable

### Key Technologies

- **Rails 8.0**: Latest Rails framework
- **Mongoid 8.1**: MongoDB ODM
- **Bootstrap 5.3**: CSS framework
- **Stimulus**: JavaScript framework
- **Turbo**: SPA-like page acceleration

### File Structure

```
app/
├── controllers/          # Application controllers
├── models/              # Mongoid models
├── views/               # ERB templates with Bootstrap styling
└── assets/              # Stylesheets and JavaScript

config/
├── mongoid.yml          # MongoDB configuration
├── routes.rb            # Application routes
└── application.rb       # Rails configuration
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test your changes
5. Submit a pull request

## License

This project is open source and available under the [MIT License](LICENSE).
