# frozen_string_literal: true

class PerformanceSerializer < ApplicationSerializer
  attributes :id, :time, :created_at, :updated_at

  belongs_to :performer, serializer: :performer
  belongs_to :event, serializer: :event
end
