class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :description, type: String
  field :date, type: DateTime
  field :location, type: String

  # Relationships
  has_and_belongs_to_many :users
  has_many :tips, dependent: :destroy
  
  # Performers are Users with _type = 'Performer'
  def performers
    users.unscoped.where(_type: 'Performer')
  end

  # Validations
  validates :title, presence: true
  validates :date, presence: true
  validates :location, presence: true

  # Callbacks to clean up many-to-many associations
  before_destroy :remove_user_associations

  private

  def remove_user_associations
    # Remove this event from all associated users
    users.each { |user| user.events.delete(self) }
  end
end
