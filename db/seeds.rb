# frozen_string_literal: true

# Database seeds generated from production data
# Generated at: 2026-05-17 10:33:44 UTC

# Users
User.find_or_create_by(email: 'admin@djtip.com') do |u|
  u.name = 'Rob Jennings'
  u.phone = '+61 2 9876 5432'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'lis@javs.org') do |u|
  u.name = 'Lisa Javs'
  u.phone = '+61 404 123 456'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'manhattan@drag.net') do |u|
  u.name = 'Aaron Manhattan'
  u.phone = '+61 404 234 567'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'betty@grumble.net') do |u|
  u.name = 'Betty Grumble'
  u.phone = '+61 404 345 678'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'tim@owe.org') do |u|
  u.name = 'Tim Owe'
  u.phone = '+61 404 456 789'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'sarah@chen.com') do |u|
  u.name = 'Sarah Chen'
  u.phone = '+61 404 567 890'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'marcus@rodriguez.net') do |u|
  u.name = 'Marcus Rodriguez'
  u.phone = '+61 404 678 901'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'emma@thompson.org') do |u|
  u.name = 'Emma Thompson'
  u.phone = '+61 404 789 012'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'ben@djtip.com') do |u|
  u.name = 'Ben Drayton'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'kooky@droppings.org') do |u|
  u.name = 'Gemma'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'matt@costain.org') do |u|
  u.name = 'Matt Costain'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'donato@dozzy.org') do |u|
  u.name = 'Donato Dozzy'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'terence@mckenna.org') do |u|
  u.name = 'Terence Mckenna'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

User.find_or_create_by(email: 'jordan@dj.net') do |u|
  u.name = 'Jordan Heads'
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

# Performers
Performer.find_or_create_by(name: 'Ben Drayton') do |p|
  p.bio = 'Electronic music producer and DJ specializing in progressive house and techno.'
  p.genre = 'Progressive House, Techno'
end

Performer.find_or_create_by(name: 'Gemma') do |p|
  p.bio = 'Chill house and ambient music curator for relaxing vibes.'
  p.genre = 'Chill House, Ambient'
end

Performer.find_or_create_by(name: 'Matt Costain') do |p|
  p.bio = 'Vinyl aficionado on the decks'
  p.genre = 'Dub Techno'
end

Performer.find_or_create_by(name: 'Donato Dozzy') do |p|
  p.genre = 'Italian Minimalism'
end

Performer.find_or_create_by(name: 'Jordan Heads') do |p|
  p.bio = 'Young trans and techno'
  p.genre = 'Driving Techno'
end

# Venues
Venue.find_or_create_by(name: 'Oxford Art Factory') do |v|
  v.venue_type = 'club'
end

Venue.find_or_create_by(name: 'Glastonbury') do |v|
  v.venue_type = 'festival'
end

# Events
event = Event.find_or_create_by(title: 'Bad Dog') do |e|
  e.location = 'Sydney Olympic Park'
  e.date = '2025-09-05T02:35:10+00:00'
  e.description = 'An outdoor electronic music festival featuring top DJs from around the world.'
end
unless event.users.include?(User.find_by(email: 'admin@djtip.com'))
  event.users << User.find_by(email: 'admin@djtip.com')
end
unless event.users.include?(User.find_by(email: 'betty@grumble.net'))
  event.users << User.find_by(email: 'betty@grumble.net')
end
unless event.users.include?(User.find_by(email: 'emma@thompson.org'))
  event.users << User.find_by(email: 'emma@thompson.org')
end
event.users << User.find_by(email: 'ben@djtip.com') unless event.users.include?(User.find_by(email: 'ben@djtip.com'))

event = Event.find_or_create_by(title: 'Loose Ends') do |e|
  e.location = 'Sky Terrace Bar'
  e.date = '2025-08-22T02:35:10+00:00'
  e.description = 'Chill house music with stunning city views.'
end
unless event.users.include?(User.find_by(email: 'admin@djtip.com'))
  event.users << User.find_by(email: 'admin@djtip.com')
end
event.users << User.find_by(email: 'lis@javs.org') unless event.users.include?(User.find_by(email: 'lis@javs.org'))
unless event.users.include?(User.find_by(email: 'manhattan@drag.net'))
  event.users << User.find_by(email: 'manhattan@drag.net')
end
unless event.users.include?(User.find_by(email: 'betty@grumble.net'))
  event.users << User.find_by(email: 'betty@grumble.net')
end
unless event.users.include?(User.find_by(email: 'kooky@droppings.org'))
  event.users << User.find_by(email: 'kooky@droppings.org')
end

event = Event.find_or_create_by(title: 'Park Beats') do |e|
  e.location = 'Metro Theatre'
  e.date = '2025-08-19T02:35:10+00:00'
  e.description = 'Heavy bass and dubstep for the hardcore electronic fans.'
end
unless event.users.include?(User.find_by(email: 'admin@djtip.com'))
  event.users << User.find_by(email: 'admin@djtip.com')
end
event.users << User.find_by(email: 'lis@javs.org') unless event.users.include?(User.find_by(email: 'lis@javs.org'))
unless event.users.include?(User.find_by(email: 'betty@grumble.net'))
  event.users << User.find_by(email: 'betty@grumble.net')
end
event.users << User.find_by(email: 'sarah@chen.com') unless event.users.include?(User.find_by(email: 'sarah@chen.com'))
unless event.users.include?(User.find_by(email: 'matt@costain.org'))
  event.users << User.find_by(email: 'matt@costain.org')
end

event = Event.find_or_create_by(title: 'Strange Signals') do |e|
  e.location = 'Sashimi Warehouse'
  e.date = '2025-08-22T21:00:00+00:00'
  e.description = 'Inner West Techno Realness'
end
unless event.users.include?(User.find_by(email: 'admin@djtip.com'))
  event.users << User.find_by(email: 'admin@djtip.com')
end
unless event.users.include?(User.find_by(email: 'matt@costain.org'))
  event.users << User.find_by(email: 'matt@costain.org')
end
unless event.users.include?(User.find_by(email: 'donato@dozzy.org'))
  event.users << User.find_by(email: 'donato@dozzy.org')
end
unless event.users.include?(User.find_by(email: 'terence@mckenna.org'))
  event.users << User.find_by(email: 'terence@mckenna.org')
end

event = Event.find_or_create_by(title: 'Matt\'s Personal Silo Kick On') do |e|
  e.location = 'The Silos'
  e.date = '2025-08-17T15:00:00+00:00'
  e.description = 'Invite Only Kick On'
end
unless event.users.include?(User.find_by(email: 'matt@costain.org'))
  event.users << User.find_by(email: 'matt@costain.org')
end
event.users << User.find_by(email: 'jordan@dj.net') unless event.users.include?(User.find_by(email: 'jordan@dj.net'))

# Tips
user = User.find_by(email: 'lis@javs.org')
event = Event.find_by(title: 'Park Beats')
if user && event
  Tip.create(
    amount: 20.0,
    currency: 'USD',
    message: 'Brilliant mixing skills! 🎧',
    user: user,
    event: event
  )
end

user = User.find_by(email: 'manhattan@drag.net')
event = Event.find_by(title: 'Loose Ends')
if user && event
  Tip.create(
    amount: 5.0,
    currency: 'USD',
    message: 'Your energy was contagious! ⚡',
    user: user,
    event: event
  )
end

user = User.find_by(email: 'betty@grumble.net')
event = Event.find_by(title: 'Bad Dog')
if user && event
  Tip.create(
    amount: 15.0,
    currency: 'USD',
    message: 'Best night ever! Thank you!',
    user: user,
    event: event
  )
end

user = User.find_by(email: 'emma@thompson.org')
event = Event.find_by(title: 'Bad Dog')
if user && event
  Tip.create(
    amount: 20.0,
    currency: 'USD',
    message: 'Incredible music selection 🔥',
    user: user,
    event: event
  )
end

user = User.find_by(email: 'admin@djtip.com')
event = Event.find_by(title: 'Strange Signals')
if user && event
  Tip.create(
    amount: 330.0,
    currency: 'USD',
    message: 'Simply the best Bumps I have had in this town !!',
    user: user,
    event: event
  )
end

user = User.find_by(email: 'terence@mckenna.org')
event = Event.find_by(title: 'Strange Signals')
if user && event
  Tip.create(
    amount: 44.0,
    currency: 'USD',
    message: 'The Machine Elves were present',
    user: user,
    event: event
  )
end

user = User.find_by(email: 'admin@djtip.com')
event = Event.find_by(title: 'Matt\'s Personal Silo Kick On')
if user && event
  Tip.create(
    amount: 399.0,
    currency: 'USD',
    message: 'Did someone mention Substituted Phenethylamines?',
    user: user,
    event: event
  )
end
