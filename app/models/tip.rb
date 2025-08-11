class Tip
  include Mongoid::Document
  include Mongoid::Timestamps

  field :amount, type: BigDecimal
  field :currency, type: String, default: 'USD'
  field :message, type: String

  # Relationships
  belongs_to :event
  belongs_to :user

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :event, presence: true
  validates :user, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_amount, -> { order(amount: :desc) }

  # Instance methods
  def formatted_amount
    "#{currency} #{amount.to_f}"
  end
end
