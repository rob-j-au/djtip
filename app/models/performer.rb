class Performer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :bio, type: String
  field :genre, type: String
  field :contact, type: String

  # Relationships
  belongs_to :event, optional: true

  # Validations
  validates :name, presence: true
  validates :genre, presence: true
end
