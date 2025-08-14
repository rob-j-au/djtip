FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    password { 'password123' }
    password_confirmation { 'password123' }
    admin { false }

    trait :admin do
      admin { true }
    end

    trait :with_event do
      after(:create) do |user|
        user.events << create(:event)
      end
    end

    trait :with_events do
      after(:create) do |user|
        user.events << create_list(:event, 2)
      end
    end

    trait :without_events do
      # Default - no events associated
    end
  end
end
