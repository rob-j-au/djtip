FactoryBot.define do
  factory :tip do
    amount { 25.50 }
    currency { 'USD' }
    message { 'Great performance! Keep it up!' }
    
    association :event
    association :user
    
    trait :large_amount do
      amount { 100.00 }
    end
    
    trait :with_euro_currency do
      currency { 'EUR' }
      amount { 20.00 }
    end
    
    trait :without_message do
      message { nil }
    end
  end
end
