class PerformerSerializer < ApplicationSerializer
  attributes :id, :name, :email, :created_at, :updated_at
  
  belongs_to :event, serializer: :event
end
