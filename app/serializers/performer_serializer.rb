class PerformerSerializer < ApplicationSerializer
  attributes :id, :name, :bio, :genre, :contact, :created_at, :updated_at
  
  has_many :events, serializer: :event
end
