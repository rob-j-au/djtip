# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Performance, type: :model do
  let(:performer) { create(:performer) }
  let(:event) { create(:event) }
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

    describe 'location validation' do
      it 'validates location format' do
        performance.location = [1, 2, 3]
        expect(performance).not_to be_valid
        expect(performance.errors[:location]).to include('must be an array of [longitude, latitude]')
      end

      it 'validates coordinates are numeric' do
        performance.location = %w[invalid invalid]
        expect(performance).not_to be_valid
        expect(performance.errors[:location]).to include('coordinates must be numeric')
      end

      it 'validates longitude range' do
        performance.location = [181, 0]
        expect(performance).not_to be_valid
        expect(performance.errors[:location]).to include('coordinates out of valid range')

        performance.location = [-181, 0]
        expect(performance).not_to be_valid
        expect(performance.errors[:location]).to include('coordinates out of valid range')
      end

      it 'validates latitude range' do
        performance.location = [0, 91]
        expect(performance).not_to be_valid
        expect(performance.errors[:location]).to include('coordinates out of valid range')

        performance.location = [0, -91]
        expect(performance).not_to be_valid
        expect(performance.errors[:location]).to include('coordinates out of valid range')
      end

      it 'allows valid coordinates' do
        performance.location = [151.2093, -33.8688]
        expect(performance).to be_valid
      end

      it 'allows blank location' do
        performance.location = nil
        expect(performance).to be_valid
      end
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

  describe 'location helpers' do
    it 'returns latitude from location array' do
      performance.location = [151.2093, -33.8688]
      expect(performance.latitude).to eq(-33.8688)
    end

    it 'returns longitude from location array' do
      performance.location = [151.2093, -33.8688]
      expect(performance.longitude).to eq(151.2093)
    end

    it 'sets latitude' do
      performance.latitude = -33.8688
      expect(performance.location[1]).to eq(-33.8688)
    end

    it 'sets longitude' do
      performance.longitude = 151.2093
      expect(performance.location[0]).to eq(151.2093)
    end

    it 'returns nil for latitude when location is not set' do
      performance.location = nil
      expect(performance.latitude).to be_nil
    end

    it 'returns nil for longitude when location is not set' do
      performance.location = nil
      expect(performance.longitude).to be_nil
    end
  end

  describe 'factory' do
    it 'creates a valid performance' do
      expect(performance).to be_valid
      expect(performance.time).to be_present
      expect(performance.location).to be_present
      expect(performance.performer).to be_present
      expect(performance.event).to be_present
    end
  end
end
