class UserSerializer < ApplicationSerializer
  attributes :id, :name, :email, :phone, :created_at, :updated_at
  
  has_many :events, serializer: :event
  has_many :tips, serializer: :tip
end
