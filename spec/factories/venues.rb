# frozen_string_literal: true

FactoryBot.define do
  factory :venue do
    name { Faker::Company.name }
    venue_type { %w[bar club festival gallery].sample }
    location { [151.2093, -33.8688] } # Default to Sydney CBD
  end
end
