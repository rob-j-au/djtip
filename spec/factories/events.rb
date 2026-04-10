FactoryBot.define do
  factory :event do
    title { Faker::Music.band }
    description { Faker::Lorem.paragraph }
    date { Faker::Time.forward(days: 30) }
    location { Faker::Address.full_address }
    
    trait :with_venue do
      association :venue
    end
  end
end
