# frozen_string_literal: true

FactoryBot.define do
  factory :performance do
    time { Faker::Time.forward(days: 30) }

    association :performer
    association :event
  end
end
