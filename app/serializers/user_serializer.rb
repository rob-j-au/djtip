class UserSerializer < ApplicationSerializer
  attributes :id, :name, :email, :created_at, :updated_at
  
  has_many :tips, serializer: :tip
end
