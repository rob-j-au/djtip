# frozen_string_literal: true

class VenueSerializer < ApplicationSerializer
  attributes :id, :name, :venue_type, :latitude, :longitude, :created_at, :updated_at

  has_many :events, serializer: :event
end
