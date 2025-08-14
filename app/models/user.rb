require_relative '../uploaders/image_uploader'

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ImageUploader::Attachment(:image) # adds an `image` virtual attribute
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  field :name, type: String
  field :email, type: String
  field :phone, type: String
  
  # Image attachment data for Shrine
  field :image_data, type: String
  
  # Admin role field
  field :admin, type: Boolean, default: false

  ## Database authenticatable
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable (optional)
  # field :sign_in_count,      type: Integer, default: 0
  # field :current_sign_in_at, type: Time
  # field :last_sign_in_at,    type: Time
  # field :current_sign_in_ip, type: String
  # field :last_sign_in_ip,    type: String

  # Relationships
  has_and_belongs_to_many :events
  has_many :tips, dependent: :destroy

  # Default scope to return only User models (exclude Performer subclass)
 # default_scope -> { where(:_type.ne => 'Performer') }

  # Scopes
  scope :non_performers, -> { where(:_type.ne => 'Performer') }

  # Validations
  validates :name, presence: true
  # Email validation is handled by Devise
  
  # Admin methods
  def admin?
    admin == true
  end
  
  def make_admin!
    update!(admin: true)
  end
end
