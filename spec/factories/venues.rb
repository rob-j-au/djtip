# frozen_string_literal: true

FactoryBot.define do
  factory :venue do
    name { Faker::Company.name }
    venue_type { %w[bar club festival gallery].sample }
    address_line1 { Faker::Address.street_address }
    address_line2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state { Faker::Address.state }
    country { 'Australia' }
    postcode { Faker::Address.postcode }
    location { [151.2093, -33.8688] } # Default to Sydney CBD
  end
end
