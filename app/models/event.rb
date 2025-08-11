class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :description, type: String
  field :date, type: DateTime
  field :location, type: String

  # Relationships
  has_many :users, dependent: :destroy
  has_many :performers, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :date, presence: true
  validates :location, presence: true
end
