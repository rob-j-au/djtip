# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Performance, type: :model do
  let(:performer) { create(:performer) }
  let(:venue) { create(:venue, location: [151.2093, -33.8688]) }
  let(:event) { create(:event, venue: venue) }
  let(:performance) { create(:performance, performer: performer, event: event) }

  describe 'validations' do
    it 'validates presence of time' do
      performance.time = nil
      expect(performance).not_to be_valid
      expect(performance.errors[:time]).to include("can't be blank")
    end

    it 'validates presence of performer' do
      performance.performer = nil
      expect(performance).not_to be_valid
      expect(performance.errors[:performer]).to include("can't be blank")
    end

    it 'validates presence of event' do
      performance.event = nil
      expect(performance).not_to be_valid
      expect(performance.errors[:event]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it 'belongs to a performer' do
      expect(performance.performer).to eq(performer)
    end

    it 'belongs to an event' do
      expect(performance.event).to eq(event)
    end
  end

  describe 'venue location delegation' do
    it 'delegates latitude to the venue via event' do
      expect(performance.event.venue.latitude).to eq(-33.8688)
    end

    it 'delegates longitude to the venue via event' do
      expect(performance.event.venue.longitude).to eq(151.2093)
    end
  end

  describe 'factory' do
    it 'creates a valid performance' do
      expect(performance).to be_valid
      expect(performance.time).to be_present
      expect(performance.performer).to be_present
      expect(performance.event).to be_present
    end
  end
end
