FactoryBot.define do
  factory :performer do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    bio { Faker::Lorem.paragraph }
    genre { Faker::Music.genre }
    contact { Faker::Internet.email }
    event { association :event }
  end
end
