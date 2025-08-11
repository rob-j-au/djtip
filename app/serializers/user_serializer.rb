class UserSerializer < ApplicationSerializer
  attributes :id, :name, :email, :phone, :created_at, :updated_at
  
  belongs_to :event, serializer: :event
  has_many :tips, serializer: :tip
end
