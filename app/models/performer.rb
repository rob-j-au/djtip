class Performer < User
  # Performer-specific fields
  field :bio, type: String
  field :genre, type: String
  field :contact, type: String

  # Relationships inherited from User:
  # - has_and_belongs_to_many :events
  # - has_many :tips, dependent: :destroy

  # Validations
  validates :genre, presence: true
  
  # Override User validations since Performer may not need email/password
  validates :email, presence: false, allow_blank: true
  validates :encrypted_password, presence: false, allow_blank: true
end
