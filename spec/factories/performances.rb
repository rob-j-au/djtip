# frozen_string_literal: true

FactoryBot.define do
  factory :performance do
    time { Faker::Time.forward(days: 30) }
    location { [Faker::Address.longitude.to_f, Faker::Address.latitude.to_f] }

    association :performer
    association :event
  end
end
