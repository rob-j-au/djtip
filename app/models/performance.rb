# frozen_string_literal: true

class Performance
  include Mongoid::Document
  include Mongoid::Timestamps

  field :time, type: Time
  field :location, type: Array

  belongs_to :performer
  belongs_to :event

  validates :time, presence: true
  validates :performer, presence: true
  validates :event, presence: true
  validate :validate_location_format

  def latitude
    location[1] if location.is_a?(Array) && location.size == 2
  end

  def longitude
    location[0] if location.is_a?(Array) && location.size == 2
  end

  def latitude=(value)
    self.location ||= [nil, nil]
    self.location[1] = value.to_f if value.present?
  end

  def longitude=(value)
    self.location ||= [nil, nil]
    self.location[0] = value.to_f if value.present?
  end

  private

  def validate_location_format
    return if location.blank?

    unless location.is_a?(Array) && location.size == 2
      errors.add(:location, 'must be an array of [longitude, latitude]')
      return
    end

    lng, lat = location
    unless lng.is_a?(Numeric) && lat.is_a?(Numeric)
      errors.add(:location, 'coordinates must be numeric')
      return
    end

    return if lng.between?(-180, 180) && lat.between?(-90, 90)

    errors.add(:location, 'coordinates out of valid range')
  end
end
