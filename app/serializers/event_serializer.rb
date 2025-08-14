class EventSerializer < ApplicationSerializer
  attributes :id, :title, :date, :location, :description, :created_at, :updated_at
  
  has_many :tips, serializer: :tip
  has_many :users, serializer: :user
  
  # Custom attribute for performers (users with _type: 'Performer')
  attribute :performers do |event|
    event.performers.map do |performer|
      {
        id: performer.id.to_s,
        name: performer.name,
        genre: performer.genre,
        bio: performer.bio
      }
    end
  end
end
