FactoryBot.define do
  factory :venue do
    name { Faker::Company.name }
    venue_type { %w[bar club festival gallery].sample }
  end
end
