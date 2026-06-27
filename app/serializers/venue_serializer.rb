# frozen_string_literal: true

class VenueSerializer < ApplicationSerializer
  attributes :id, :name, :venue_type, :address_line1, :address_line2,
             :city, :state, :country, :postcode, :latitude, :longitude,
             :created_at, :updated_at

  has_many :events, serializer: :event
end
