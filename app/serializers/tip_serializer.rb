class TipSerializer < ApplicationSerializer
  attributes :id, :amount, :currency, :message, :created_at, :updated_at
  
  belongs_to :event, serializer: :event
  belongs_to :user, serializer: :user
  
  attribute :formatted_amount do |tip|
    "#{tip.currency} #{tip.amount}"
  end
end
