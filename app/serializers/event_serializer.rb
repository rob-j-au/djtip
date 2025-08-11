class EventSerializer < ApplicationSerializer
  attributes :id, :title, :date, :location, :description, :created_at, :updated_at
  
  has_many :tips, serializer: :tip
  has_many :performers, serializer: :performer
  has_many :users, serializer: :user
end
