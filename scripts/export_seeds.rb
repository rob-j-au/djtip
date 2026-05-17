#!/usr/bin/env ruby
# frozen_string_literal: true

# Export current database state to seeds.rb

puts 'Exporting database to seeds.rb...'

File.open('db/seeds.rb', 'w') do |f|
  f.puts '# Database seeds generated from production data'
  f.puts "# Generated at: #{Time.current}"
  f.puts ''

  # Users
  f.puts '# Users'
  User.all.each do |user|
    f.puts "User.find_or_create_by(email: '#{user.email}') do |u|"
    f.puts "  u.name = '#{user.name}'"
    f.puts "  u.phone = '#{user.phone}'" if user.phone.present?
    f.puts "  u.password = 'password123'"
    f.puts "  u.password_confirmation = 'password123'"
    f.puts 'end'
    f.puts ''
  end

  # Performers
  f.puts '# Performers'
  Performer.all.each do |performer|
    name = performer.name.gsub("'", "\\\\'")
    f.puts "Performer.find_or_create_by(name: '#{name}') do |p|"
    f.puts "  p.bio = '#{performer.bio.gsub("'", "\\\\'")}'" if performer.bio.present?
    f.puts "  p.genre = '#{performer.genre.gsub("'", "\\\\'")}'" if performer.genre.present?
    f.puts "  p.contact = '#{performer.contact}'" if performer.contact.present?
    f.puts 'end'
    f.puts ''
  end

  # Venues
  f.puts '# Venues'
  Venue.all.each do |venue|
    name = venue.name.gsub("'", "\\\\'")
    f.puts "Venue.find_or_create_by(name: '#{name}') do |v|"
    f.puts "  v.venue_type = '#{venue.venue_type}'" if venue.venue_type.present?
    f.puts 'end'
    f.puts ''
  end

  # Events
  f.puts '# Events'
  Event.all.each do |event|
    title = event.title.gsub("'", "\\\\'")
    location = event.location.gsub("'", "\\\\'")
    user_emails = event.users.map(&:email).compact
    venue_name = event.venue&.name&.gsub("'", "\\\\'")

    f.puts "event = Event.find_or_create_by(title: '#{title}') do |e|"
    f.puts "  e.location = '#{location}'"
    f.puts "  e.date = '#{event.date.iso8601}'" if event.date
    f.puts "  e.description = '#{event.description.gsub("'", "\\\\'")}'" if event.description.present?
    f.puts "  e.venue = Venue.find_by(name: '#{venue_name}')" if venue_name
    f.puts 'end'

    if user_emails.any?
      user_emails.each do |email|
        f.puts "event.users << User.find_by(email: '#{email}') unless event.users.include?(User.find_by(email: '#{email}'))"
      end
    end
    f.puts ''
  end

  # Tips
  f.puts '# Tips'
  Tip.all.each do |tip|
    user_email = tip.user&.email
    event_title = tip.event&.title&.gsub("'", "\\\\'")
    next unless user_email && event_title

    f.puts "user = User.find_by(email: '#{user_email}')"
    f.puts "event = Event.find_by(title: '#{event_title}')"
    f.puts 'Tip.create('
    f.puts "  amount: #{tip.amount},"
    f.puts "  currency: '#{tip.currency}',"
    f.puts "  message: '#{tip.message.gsub("'", "\\\\'")}',  " if tip.message.present?
    f.puts '  user: user,'
    f.puts '  event: event'
    f.puts ') if user && event'
    f.puts ''
  end
end

puts 'Seeds file generated successfully!'
puts "Total records: Users=#{User.count}, Performers=#{Performer.count}, Venues=#{Venue.count}, Events=#{Event.count}, Tips=#{Tip.count}"
