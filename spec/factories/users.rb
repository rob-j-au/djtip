FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    password { 'password123' }
    password_confirmation { 'password123' }
    event { association :event }
    admin { false }

    trait :admin do
      admin { true }
    end

    trait :without_event do
      event { nil }
    end
  end
end
