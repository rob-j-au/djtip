FactoryBot.define do
  factory :performer do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    bio { Faker::Lorem.paragraph }
    genre { Faker::Music.genre }
    contact { Faker::Internet.email }
    
    # Don't auto-create events - let tests handle event associations explicitly
    # This prevents conflicts when tests want to associate with specific events
  end
end
