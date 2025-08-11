FactoryBot.define do
  factory :performer do
    name { Faker::Name.name }
    bio { Faker::Lorem.paragraph }
    genre { Faker::Music.genre }
    contact { Faker::Internet.email }
    event { association :event }
  end
end
