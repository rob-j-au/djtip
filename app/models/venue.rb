# frozen_string_literal: true

class Venue
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :venue_type, type: String

  validates :name, presence: true
  validates :venue_type, presence: true, inclusion: { in: %w[bar club festival gallery] }

  has_many :events
end
