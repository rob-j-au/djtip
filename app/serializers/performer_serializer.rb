class PerformerSerializer < ApplicationSerializer
  attributes :id, :name, :bio, :genre, :contact, :created_at, :updated_at
  
  belongs_to :event, serializer: :event
end
