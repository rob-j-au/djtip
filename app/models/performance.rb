# frozen_string_literal: true

class Performance
  include Mongoid::Document
  include Mongoid::Timestamps

  field :time, type: Time

  belongs_to :performer
  belongs_to :event

  validates :time, presence: true
  validates :performer, presence: true
  validates :event, presence: true

  delegate :latitude, :longitude, :location, to: :venue, prefix: true, allow_nil: true

  private

  def venue
    event&.venue
  end
end
