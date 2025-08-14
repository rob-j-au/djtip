# Database Seeds for djtip Application
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting database seeding..."

# Clear existing data (optional - uncomment if you want to reset)
# puts "Clearing existing data..."
# User.destroy_all
# Event.destroy_all
# Performer.destroy_all
# Tip.destroy_all

# Create Events first (needed for user associations)
puts "Creating events..."

events = [
  {
    title: "Summer Vibes Festival",
    description: "An outdoor electronic music festival featuring top DJs from around the world.",
    location: "Sydney Olympic Park",
    date: 3.weeks.from_now
  },
  {
    title: "Underground Sessions",
    description: "Intimate underground techno experience in a warehouse setting.",
    location: "Secret Warehouse Location",
    date: 2.weeks.from_now
  },
  {
    title: "Rooftop Sunset",
    description: "Chill house music with stunning city views.",
    location: "Sky Terrace Bar",
    date: 1.week.from_now
  },
  {
    title: "Bass Drop Night",
    description: "Heavy bass and dubstep for the hardcore electronic fans.",
    location: "Metro Theatre",
    date: 4.days.from_now
  }
]

created_events = []
events.each do |event_data|
  event = Event.find_or_create_by(title: event_data[:title]) do |e|
    e.description = event_data[:description]
    e.location = event_data[:location]
    e.date = event_data[:date]
  end
  created_events << event
  if event.persisted? && event.created_at == event.updated_at
    puts "  ✅ Created event: #{event.title}"
  else
    puts "  ⏭️  Event already exists: #{event.title}"
  end
end

# Create 5 Users with realistic data
puts "\nCreating users..."

users_data = [
  {
    name: "Admin User",
    email: "admin@djtip.com",
    password: "password123",
    password_confirmation: "password123",
    admin: true,
    phone: "+61 2 9876 5432"
  },
  {
    name: "Stephen Allkins",
    email: "steve@angry.org",
    password: "password123",
    password_confirmation: "password123",
    admin: false,
    phone: "+61 404 123 456"
  },
  {
    name: "Ben Drayton",
    email: "ben@drayton.org",
    password: "password123",
    password_confirmation: "password123",
    admin: false,
    phone: "+61 404 234 567"
  },
  {
    name: "Emma Rodriguez",
    email: "emma.rodriguez@email.com",
    password: "password123",
    password_confirmation: "password123",
    admin: false,
    phone: "+61 404 345 678"
  },
  {
    name: "James Wilson",
    email: "james.wilson@email.com",
    password: "password123",
    password_confirmation: "password123",
    admin: false,
    phone: "+61 404 456 789"
  }
]

created_users = []
users_data.each do |user_data|
  user = User.find_or_create_by(email: user_data[:email]) do |u|
    u.name = user_data[:name]
    u.password = user_data[:password]
    u.password_confirmation = user_data[:password_confirmation]
    u.admin = user_data[:admin]
    u.phone = user_data[:phone]
  end
  created_users << user
  if user.persisted? && user.created_at == user.updated_at
    puts "  ✅ Created user: #{user.name} (#{user.admin? ? 'Admin' : 'Regular'})"
  else
    puts "  ⏭️  User already exists: #{user.name} (#{user.email})"
  end
end

# Associate users with events (many-to-many relationship)
puts "\nAssociating users with events..."

# Admin user attends all events
admin_user = created_users.first
admin_user.events = created_events
puts "  ✅ Admin user associated with all #{created_events.count} events"

# Regular users attend random events
created_users[1..-1].each do |user|
  # Each user attends 1-3 random events
  num_events = rand(1..3)
  user_events = created_events.sample(num_events)
  user.events = user_events
  puts "  ✅ #{user.name} associated with #{user_events.count} events"
end

# Create Performers
puts "\nCreating performers..."

performers_data = [
  {
    name: "DJ Pulse",
    email: "djpulse@djtip.com",
    bio: "Electronic music producer and DJ specializing in progressive house and techno.",
    genre: "Progressive House, Techno",
    event: created_events[0]
  },
  {
    name: "Bass Master",
    email: "bassmaster@djtip.com",
    bio: "Underground bass music specialist with 10+ years experience.",
    genre: "Dubstep, Bass",
    event: created_events[1]
  },
  {
    name: "Sunset Sounds",
    email: "sunsetsounds@djtip.com",
    bio: "Chill house and ambient music curator for relaxing vibes.",
    genre: "Chill House, Ambient",
    event: created_events[2]
  },
  {
    name: "Drop Zone",
    email: "dropzone@djtip.com",
    bio: "High-energy electronic music for the dance floor.",
    genre: "Electro, Big Room",
    event: created_events[3]
  }
]

created_performers = []
performers_data.each do |performer_data|
  performer = Performer.find_or_create_by(email: performer_data[:email]) do |p|
    p.name = performer_data[:name]
    p.password = 'password123'
    p.password_confirmation = 'password123'
    p.bio = performer_data[:bio]
    p.genre = performer_data[:genre]
    p.event = performer_data[:event]
  end
  created_performers << performer
  if performer.persisted? && performer.created_at == performer.updated_at
    puts "  ✅ Created performer: #{performer.name}"
  else
    puts "  ⏭️  Performer already exists: #{performer.name}"
  end
end

# Create some sample tips
puts "\nCreating sample tips..."

tip_messages = [
  "Amazing set! Keep it up! 🎵",
  "Best night ever! Thank you!",
  "Incredible music selection 🔥",
  "You made my night! 💫",
  "Fantastic vibes, loved every minute!",
  "Outstanding performance! 👏",
  "Music was perfect for the mood 🎶",
  "Thanks for an unforgettable experience!",
  "Your energy was contagious! ⚡",
  "Brilliant mixing skills! 🎧"
]

# Create tips from users to events
created_users[1..-1].each do |user|
  # Each user gives 1-2 tips to events they're attending
  user.events.each do |event|
    next if rand > 0.7 # 70% chance of tipping per event
    
    # Skip if tip already exists for this user/event combination
    existing_tip = Tip.where(user: user, event: event).first
    if existing_tip
      puts "  ⏭️  Tip already exists: #{user.name} -> #{event.title}"
      next
    end
    
    tip = Tip.create!(
      user: user,
      event: event,
      amount: [5, 10, 15, 20, 25, 50].sample,
      message: tip_messages.sample
    )
    puts "  ✅ #{user.name} tipped $#{tip.amount} to #{event.title}"
  end
end

# Summary
puts "\n🎉 Database seeding completed successfully!"
puts "\nSummary:"
puts "  👥 Users: #{User.count} (#{User.where(admin: true).count} admin, #{User.where(admin: false).count} regular)"
puts "  🎪 Events: #{Event.count}"
puts "  🎵 Performers: #{Performer.count}"
puts "  💰 Tips: #{Tip.count} (Total: $#{Tip.sum(:amount)})"
puts "\nLogin credentials:"
puts "  Admin: admin@djtip.com / password123"
puts "  Users: [name]@email.com / password123"
puts "\n✨ Ready to rock! Visit http://localhost:3000/admin to get started."
